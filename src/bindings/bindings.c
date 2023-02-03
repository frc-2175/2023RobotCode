#include <assert.h>

#include "./md.h"
#include "./md.c"

#define NodeLine(node) MD_CodeLocFromNode(node).line
#define MAX_ARGS 16
#define MAX_BASE_CLASSES 10

// Memory allocator for Metadesk
MD_Arena* a;

// Predefined MD_Joins because the API is terrible
MD_StringJoin newlineJoin = MD_ZERO_STRUCT;
MD_StringJoin commaJoin = MD_ZERO_STRUCT;

void printIndent(int level) {
	for (int i = 0; i < level; i++) {
		printf("| ");
	}
}

void DumpNodeR(MD_Node* node, const char* marker, int level) {
	printIndent(level);
	printf("%s %.*s\n", marker, MD_S8VArg(node->string));
	if (!MD_NodeIsNil(node->first_child) || !MD_NodeIsNil(node->first_tag)) {
		printIndent(level);
		printf("|\\\n");
	}

	for (MD_EachNode(n, node->first_tag)) {
		DumpNodeR(n, "@", level + 1);
	}
	for (MD_EachNode(n, node->first_child)) {
		DumpNodeR(n, "*", level + 1);
	}
}

void DumpNode(MD_Node* node) {
	DumpNodeR(node, "*", 0);
}

MD_String8 TrimNewlines(MD_String8 string) {
	for (MD_u64 i = 0; i < string.size; i += 1) {
		if (!(string.str[i] == '\n' || string.str[i] == '\r')) {
			string = MD_S8Skip(string, i);
			break;
		}
	}
	for (MD_u64 i = string.size - 1; i < string.size; i -= 1) {
		if (!(string.str[i] == '\n' || string.str[i] == '\r')) {
			string = MD_S8Prefix(string, i + 1);
			break;
		}
	}
	return string;
}

MD_String8 ParseType(MD_Node* start, MD_Node* end) {
	MD_String8List pieces = {0};
	for (MD_Node* it = start; !MD_NodeIsNil(it) && it != end; it = it->next) {
		MD_S8ListPush(a, &pieces, it->string);
	}
	if (pieces.node_count == 0) {
		return MD_S8Lit("void");
	} else {
		return MD_S8ListJoin(a, pieces, &(MD_StringJoin) {
			.mid = MD_S8Lit(" "),
		});
	}
}

typedef struct {
	MD_String8 Doc;
	MD_String8 ReturnType;
	MD_String8 Name; // If there is an alias, this will be the alias name, to be used everywhere except the actual WPILib call.
	MD_String8 WPILibName; // If there is an alias, this may be different from Name.

	MD_String8 CustomCppBody;

	int NumArgs;
	MD_String8 ArgTypes[MAX_ARGS];
	MD_String8 ArgNames[MAX_ARGS];
	int ArgDerefs[MAX_ARGS];
	MD_String8 ArgCasts[MAX_ARGS];
	MD_String8 ArgEnums[MAX_ARGS];
	MD_String8 ArgDefaults[MAX_ARGS];
	MD_String8 ArgConstructs[MAX_ARGS];

	int isConstructor;
	MD_String8 ClassName;

	MD_Node* After;

	MD_Message* Error;
} ParseFuncResult;

ParseFuncResult ParseFunc(MD_Node* n) {
	ParseFuncResult res = {0};

	if (MD_NodeHasTag(n, MD_S8Lit("doc"), 0)) {
		res.Doc = MD_TagFromString(n, MD_S8Lit("doc"), 0)->first_child->string;
	}

	res.isConstructor = MD_NodeHasTag(n, MD_S8Lit("constructor"), 0);
	res.ClassName = n->parent->string;

	MD_Node* argsNode = NULL;
	MD_Node* terminator = NULL;

	for (MD_EachNode(it, n)) {
		if (
			(it->flags & MD_NodeFlag_HasParenLeft)
			&& (it->flags & MD_NodeFlag_HasParenRight)
		) {
			if (argsNode) {
				return (ParseFuncResult) {
					.Error = &(MD_Message) {
						.node = it,
							.kind = MD_MessageKind_Error,
							.string = MD_S8Lit("Found multiple sets of arguments for function (are you missing a semicolon?)"),
					},
				};
			}
			argsNode = it;
		}

		if (it->flags & MD_NodeFlag_IsBeforeSemicolon) {
			// This node terminates the definition
			terminator = it;
			break;
		}
	}
	if (!argsNode) {
		return (ParseFuncResult) {
			.Error = &(MD_Message) {
				.node = n,
					.kind = MD_MessageKind_Error,
					.string = MD_S8Lit("Did not find arguments for function"),
			},
		};
	}

	MD_Node* nameNode = argsNode->prev;
	res.Name = nameNode->string;
	res.WPILibName = nameNode->string;
	if (MD_NodeHasTag(n, MD_S8Lit("alias"), 0)) {
		res.Name = MD_TagFromString(n, MD_S8Lit("alias"), 0)->first_child->string;
	}

	// Everything before the name is the type
	res.ReturnType = ParseType(n, nameNode);

	// Arg parsing - args are separated by commas
	res.NumArgs = 0;
	MD_Node* argStart = NULL;
	for (MD_EachNode(it, argsNode->first_child)) {
		if (!argStart) {
			argStart = it;
		}

		if (it->flags & MD_NodeFlag_IsBeforeComma || MD_NodeIsNil(it->next)) {
			res.ArgNames[res.NumArgs] = it->string;
			res.ArgTypes[res.NumArgs] = ParseType(argStart, it);

			MD_Node* derefTag = MD_TagFromString(argStart, MD_S8Lit("deref"), 0);
			if (!MD_NodeIsNil(derefTag)) {
				res.ArgDerefs[res.NumArgs] = 1;
			}

			MD_Node* castTag = MD_TagFromString(argStart, MD_S8Lit("cast"), 0);
			if (!MD_NodeIsNil(castTag)) {
				res.ArgCasts[res.NumArgs] = castTag->first_child->string;
			}

			MD_Node* enumTag = MD_TagFromString(argStart, MD_S8Lit("enum"), 0);
			if (!MD_NodeIsNil(enumTag)) {
				res.ArgEnums[res.NumArgs] = enumTag->first_child->string;
			}

			MD_Node* defaultTag = MD_TagFromString(argStart, MD_S8Lit("default"), 0);
			if (!MD_NodeIsNil(defaultTag)) {
				res.ArgDefaults[res.NumArgs] = defaultTag->first_child->string;
			}

			MD_Node* constructTag = MD_TagFromString(argStart, MD_S8Lit("construct"), 0);
			if (!MD_NodeIsNil(constructTag)) {
				res.ArgConstructs[res.NumArgs] = constructTag->first_child->string;
			}

			res.NumArgs++;
			argStart = NULL;
		}
	}

	// Custom body
	if (argsNode != terminator) {
		res.CustomCppBody = argsNode->next->string;
		res.CustomCppBody = MD_S8ListJoin(a,
			MD_S8Split(a, res.CustomCppBody, 1, (MD_String8[]) { MD_S8Lit("\r") }),
			NULL
		);
		res.CustomCppBody = TrimNewlines(MD_S8ChopWhitespace(TrimNewlines(res.CustomCppBody))); // this could sure be a lot cleaner lol (if they fix some bugs in metadesk)
	}

	res.After = terminator->next;

	return res;
}

typedef struct {
	MD_String8 Name;

	int NumValues;
	MD_String8 ValueNames[MAX_ARGS];
	int ValueNums[MAX_ARGS];

	MD_Message* Error;
} ParseEnumResult;

ParseEnumResult ParseEnum(MD_Node* n) {
	ParseEnumResult res = {0};
	res.Name = n->string;

	for (MD_EachNode(it, n->first_child)) {
		res.ValueNames[res.NumValues] = it->string;
		res.ValueNums[res.NumValues] = (int)MD_CStyleIntFromString(it->first_child->string);
		res.NumValues++;
	}

	return res;
}

typedef struct {
	MD_String8 Name;
	int NumMembers;
	MD_String8List MemberNames[MAX_ARGS];
	MD_String8 MemberTypes[MAX_ARGS];
} ParseStructResult;

ParseStructResult ParseStruct(MD_Node* n) {
	ParseStructResult res = {0};
	res.Name = n->string;

	for (MD_EachNode(it, n->first_child)) {
		res.MemberTypes[res.NumMembers] = ParseType(it, it->next);
		while (!(it->flags & MD_NodeFlag_IsBeforeSemicolon) && !MD_NodeIsNil(it->next)) {
			it = it->next;
			MD_S8ListPush(a, &res.MemberNames[res.NumMembers], it->string);
		}
		
		res.NumMembers++;
	}
	return res;
}

MD_String8 GenStruct(ParseStructResult parsedStruct) {
	MD_String8List members;

	for (int i = 0; i < parsedStruct.NumMembers; i++) {
		MD_S8ListPushFmt(a, &members, "%S %S", parsedStruct.MemberTypes[i], MD_S8ListJoin(a, parsedStruct.MemberNames[i], &commaJoin));
	}

	MD_StringJoin join = {MD_S8Lit(""), MD_S8Lit("; "), MD_S8Lit(";")};

	return MD_S8Fmt(a, "typedef struct { %S } %S;", MD_S8ListJoin(a, members, &join), parsedStruct.Name);
}

MD_String8 CTypeToLuaType(MD_String8 cType) {
	if (MD_S8Match(cType, MD_S8Lit("bool"), 0)) {
		return MD_S8Lit("boolean");
	}
	if (MD_S8Match(cType, MD_S8Lit("int"), 0)) {
		return MD_S8Lit("integer");
	}
	if (
		MD_S8Match(cType, MD_S8Lit("float"), 0)
		|| MD_S8Match(cType, MD_S8Lit("double"), 0)
	) {
		return MD_S8Lit("number");
	}
	if (MD_S8Match(cType, MD_S8Lit("void"), 0)) {
		return MD_S8Lit("nil");
	}
	if (
		MD_S8Match(cType, MD_S8Lit("const char*"), 0)
		|| MD_S8Match(cType, MD_S8Lit("const char *"), 0)
		|| MD_S8Match(cType, MD_S8Lit("char const*"), 0)
		|| MD_S8Match(cType, MD_S8Lit("char const *"), 0)) {
		return MD_S8Lit("string");
	}

	return MD_S8Lit("any");
}

MD_String8 GenMethodName(MD_String8 luaClassName, MD_String8 funcName) {
	return MD_S8Fmt(a, "%S_%S", luaClassName, funcName);
}

MD_String8List GenCppSignatureArgs(ParseFuncResult parsedFunc, MD_b32 includeThis) {
	MD_String8List args = {0};
	if (includeThis) {
		MD_S8ListPush(a, &args, MD_S8Lit("void* _this"));
	}
	for (int i = 0; i < parsedFunc.NumArgs; i++) {
		MD_S8ListPushFmt(a, &args,
			"%S %S",
			parsedFunc.ArgTypes[i], parsedFunc.ArgNames[i]
		);
	}
	return args;
}

MD_String8List GenCppCallArgs(ParseFuncResult parsedFunc) {
	MD_String8List cppCallArgs = {0};
	for (int i = 0; i < parsedFunc.NumArgs; i++) {
		MD_String8 deref = MD_S8Lit("");
		if (parsedFunc.ArgDerefs[i]) {
			deref = MD_S8Lit("*");
		}

		MD_String8 cast = MD_S8Lit("");
		if (parsedFunc.ArgCasts[i].size > 0) {
			cast = MD_S8Fmt(a, "(%S)", parsedFunc.ArgCasts[i]);
		}
		if (parsedFunc.ArgConstructs[i].size > 0) {
			MD_S8ListPushFmt(a, &cppCallArgs,
				"%S(%S%S%S)",
				parsedFunc.ArgConstructs[i], deref, cast, parsedFunc.ArgNames[i]
			);
		} else {
			MD_S8ListPushFmt(a, &cppCallArgs,
				"%S%S%S",
				deref, cast, parsedFunc.ArgNames[i]
			);
		}
	}
	return cppCallArgs;
}

MD_String8 GenLuaDocComment(ParseFuncResult parsedFunc) {
	MD_String8List typeLines = {0};
	for (int i = 0; i < parsedFunc.NumArgs; i++) {
		MD_String8 maybeQuestionMark = {0};
		if (parsedFunc.ArgDefaults[i].size > 0) {
			maybeQuestionMark = MD_S8Lit("?");
		}

		MD_S8ListPushFmt(a, &typeLines,
			"---@param %S%S %S",
			parsedFunc.ArgNames[i], maybeQuestionMark, CTypeToLuaType(parsedFunc.ArgTypes[i])
		);
	}
	if (parsedFunc.ReturnType.size > 0) {
		if (parsedFunc.isConstructor) {
			MD_S8ListPushFmt(a, &typeLines,
				"---@return %S",
				parsedFunc.ClassName
			);
		} else {
			MD_String8 luaType = CTypeToLuaType(parsedFunc.ReturnType);
			if (!MD_S8Match(luaType, MD_S8Lit("nil"), 0)) {
				MD_S8ListPushFmt(a, &typeLines,
					"---@return %S",
					CTypeToLuaType(parsedFunc.ReturnType)
				);
			}
		}
	}

	MD_String8 doc = {0};
	if (parsedFunc.Doc.size > 0) {
		doc = MD_S8Fmt(a, "-- %S\n", parsedFunc.Doc);
	}

	MD_String8 types = MD_S8ListJoin(a, typeLines, &newlineJoin);
	if (types.size > 0) {
		types = MD_S8Fmt(a, "%S\n", types);
	}

	return MD_S8Fmt(a,
		"%S"
		"%S",
		doc,
		types
	);
}

MD_String8List GenLuaSignatureArgs(ParseFuncResult parsedFunc) {
	MD_String8List args = {0};
	for (int i = 0; i < parsedFunc.NumArgs; i++) {
		MD_S8ListPush(a, &args, parsedFunc.ArgNames[i]);
	}
	return args;
}

MD_String8List GenLuaArgModifiers(ParseFuncResult parsedFunc) {
	MD_String8List mods = {0};

	// process defaults
	for (int i = 0; i < parsedFunc.NumArgs; i++) {
		if (parsedFunc.ArgDefaults[i].size > 0) {
			MD_S8ListPushFmt(a, &mods,
				"    %S = %S or %S",
				parsedFunc.ArgNames[i], parsedFunc.ArgNames[i], parsedFunc.ArgDefaults[i]
			);
		}
	}

	// process enums
	for (int i = 0; i < parsedFunc.NumArgs; i++) {
		if (parsedFunc.ArgEnums[i].size > 0) {
			MD_S8ListPushFmt(a, &mods,
				"    %S = AssertEnumValue(%S, %S)",
				parsedFunc.ArgNames[i], parsedFunc.ArgEnums[i], parsedFunc.ArgNames[i]
			);
		}
	}

	// assert types and stuff now that we have values for everything
	for (int i = 0; i < parsedFunc.NumArgs; i++) {
		if (MD_S8Match(parsedFunc.ArgTypes[i], MD_S8Lit("int"), 0)) {
			MD_S8ListPushFmt(a, &mods,
				"    %S = AssertInt(%S)",
				parsedFunc.ArgNames[i], parsedFunc.ArgNames[i]
			);
		}
		if (
			MD_S8Match(parsedFunc.ArgTypes[i], MD_S8Lit("float"), 0)
			|| MD_S8Match(parsedFunc.ArgTypes[i], MD_S8Lit("double"), 0)
		) {
			MD_S8ListPushFmt(a, &mods,
				"    %S = AssertNumber(%S)",
				parsedFunc.ArgNames[i], parsedFunc.ArgNames[i]
			);
		}
	}

	return mods;
}

MD_String8List GenLuaCallArgs(ParseFuncResult parsedFunc, MD_b32 isMethod) {
	MD_String8List args = {0};
	if (isMethod) {
		MD_S8ListPush(a, &args, MD_S8Lit("self._this"));
	}
	for (int i = 0; i < parsedFunc.NumArgs; i++) {
		MD_S8ListPush(a, &args, parsedFunc.ArgNames[i]);
	}
	return args;
}

typedef struct {
	// Common data, types, args, etc.
	ParseFuncResult ParsedFunction;

	MD_String8 LuaClassName;
	MD_String8 CppClassName;
	MD_String8 FunctionName; // either function or method, depending on context
	MD_b32 IsConstructor;
	MD_b32 IsStatic;

	// Various overrides of the default
	MD_String8 CustomCppReturnType;
	MD_String8 CustomCppBody;
	MD_String8 CustomLuaBody;
	MD_b32 SkipLuaWrapper;
} GenOutputOptions;

typedef struct {
	MD_String8 CppFunction;
	MD_String8 LuaBindingSignature;
	MD_String8 LuaFunction;
} GenOutputResult;

/**
 * Takes a pile of function data and produces the actual source code to write
 * to our output files. Does not actually understand
 *
 * TODO??
 */
GenOutputResult GenOutput(GenOutputOptions opts) {
	MD_b32 isMethod = opts.CppClassName.size > 0 && !opts.IsStatic;

	MD_String8 cppWrapperName = {0};
	if (isMethod) {
		cppWrapperName = GenMethodName(opts.LuaClassName, opts.FunctionName);
	} else {
		cppWrapperName = opts.FunctionName;
	}

	MD_String8List cppSignatureArgs = GenCppSignatureArgs(opts.ParsedFunction, isMethod && !opts.IsConstructor);
	MD_String8 luaDocComment = GenLuaDocComment(opts.ParsedFunction);
	MD_String8List luaSignatureArgs = GenLuaSignatureArgs(opts.ParsedFunction);
	MD_String8List luaArgModifiers = GenLuaArgModifiers(opts.ParsedFunction);
	MD_String8List cppCallArgs = GenCppCallArgs(opts.ParsedFunction);
	MD_String8List luaCallArgs = GenLuaCallArgs(opts.ParsedFunction, isMethod);

	MD_String8 returnType = opts.CustomCppReturnType.size > 0 ? opts.CustomCppReturnType : opts.ParsedFunction.ReturnType;

	MD_String8 cppDocs = opts.ParsedFunction.Doc.size > 0 ? MD_S8Fmt(a, "// %S\n", opts.ParsedFunction.Doc) : (MD_String8) { 0 };
	MD_String8 cppSignature = MD_S8Fmt(a,
		"%S %S(%S)",
		returnType, cppWrapperName, MD_S8ListJoin(a, cppSignatureArgs, &commaJoin)
	);

	MD_String8 luaArgModifiersStr = MD_S8ListJoin(a, luaArgModifiers, &(MD_StringJoin) {
		.mid = MD_S8Lit("\n"),
			.post = luaArgModifiers.node_count > 0 ? MD_S8Lit("\n") : MD_S8Lit(""),
	});

	// Generate both wrapper function bodies at once
	MD_String8 cppBody = {0};
	MD_String8 luaBody = {0};
	MD_b32 isVoid = returnType.size == 0 || MD_S8Match(returnType, MD_S8Lit("void"), 0);
	if (isMethod) {
		if (isVoid) {
			cppBody = MD_S8Fmt(a,
				"    ((%S*)_this)\n"
				"        ->%S(%S);",
				opts.CppClassName,
				opts.ParsedFunction.WPILibName, MD_S8ListJoin(a, cppCallArgs, &commaJoin)
			);
			luaBody = MD_S8Fmt(a,
				"%S"
				"    ffi.C.%S(%S)",
				luaArgModifiersStr,
				cppWrapperName, MD_S8ListJoin(a, luaCallArgs, &commaJoin)
			);
		} else {
			cppBody = MD_S8Fmt(a,
				"    auto _result = ((%S*)_this)\n"
				"        ->%S(%S);\n"
				"    return (%S)_result;",
				opts.CppClassName,
				opts.ParsedFunction.WPILibName, MD_S8ListJoin(a, cppCallArgs, &commaJoin),
				returnType
			);
			luaBody = MD_S8Fmt(a,
				"%S"
				"    return ffi.C.%S(%S)",
				luaArgModifiersStr,
				cppWrapperName, MD_S8ListJoin(a, luaCallArgs, &commaJoin)
			);
		}
	} else {
		// Not a method, just a plain ol' function
		if (isVoid) {
			cppBody = MD_S8Fmt(a,
				"    %S::%S(%S);",
				opts.CppClassName, opts.ParsedFunction.WPILibName, MD_S8ListJoin(a, cppCallArgs, &commaJoin)
			);
			luaBody = MD_S8Fmt(a,
				"%S"
				"    ffi.C.%S(%S)",
				luaArgModifiersStr,
				cppWrapperName, MD_S8ListJoin(a, luaCallArgs, &commaJoin)
			);
		} else {
			cppBody = MD_S8Fmt(a,
				"    auto _result = %S::%S(%S);\n"
				"    return (%S)_result;",
				opts.CppClassName, opts.ParsedFunction.WPILibName, MD_S8ListJoin(a, cppCallArgs, &commaJoin),
				returnType
			);
			luaBody = MD_S8Fmt(a,
				"%S"
				"    return ffi.C.%S(%S)",
				luaArgModifiersStr,
				cppWrapperName, MD_S8ListJoin(a, luaCallArgs, &commaJoin)
			);
		}
	}

	// Optionally override the generated bodies
	if (opts.CustomCppBody.size > 0) {
		cppBody = opts.CustomCppBody;
	}
	// NOTE(ben): This comes second right now because it works better for
	// DifferentialDrive. Maybe this won't be the right choice in the future?
	if (opts.ParsedFunction.CustomCppBody.size > 0) {
		cppBody = opts.ParsedFunction.CustomCppBody;
	}
	if (opts.CustomLuaBody.size > 0) {
		luaBody = MD_S8Fmt(a,
			"%S"
			"%S",
			luaArgModifiersStr,
			opts.CustomLuaBody
		);
	}

	// Generate full C++ wrapper function
	MD_String8 cppFunction = MD_S8Fmt(a,
		"%S"
		"LUAFUNC %S {\n"
		"%S\n"
		"}\n",
		cppDocs,
		cppSignature,
		cppBody
	);

	// Generate full nice Lua function
	MD_String8 methodReceiver = {0};
	if (isMethod) {
		methodReceiver = MD_S8Fmt(a, "%S:", opts.LuaClassName);
	}

	MD_String8 lowercasedName = MD_S8Copy(a, opts.ParsedFunction.Name);
	lowercasedName.str[0] = MD_CharToLower(lowercasedName.str[0]);

	MD_String8 luaFunction = MD_S8Fmt(a,
		"%S"
		"function %S%S(%S)\n"
		"%S\n"
		"end\n",
		luaDocComment,
		methodReceiver, lowercasedName, MD_S8ListJoin(a, luaSignatureArgs, &commaJoin),
		luaBody
	);

	GenOutputResult result = {0};
	result.CppFunction = cppFunction;
	result.LuaBindingSignature = MD_S8Fmt(a, "%S;", cppSignature);
	if (!opts.SkipLuaWrapper) {
		result.LuaFunction = luaFunction;
	}

	return result;
}

/**
 * Generate bindings for all functions within a single class, either a primary
 * class or a base class.
 *
 * This is the only function that handles class-method-specific tags like
 * @constructor.
 *
 * Returns an error message if there was a problem.
 */
MD_Message* addClassFuncs(
	/**
	 * Can be either a normal class or base class. Can be used to look up all
	 * the functions to bind to, but NOT to get a name, because when generating
	 * functions using a base class, you still want to use the primary class's
	 * name.
	 */
	MD_Node* classNode,
	/**
	 * Always refers to the primary class being generated for. If you are
	 * calling this function without a base class, pass the primary class for
	 * both of these arguments.
	 */
	MD_Node* primaryClassNode,

	MD_String8List* cppDefs,
	MD_String8List* luaSignatures,
	MD_String8List* luaDefs
) {
	MD_Node* funcNode = classNode->first_child;
	while (1) {
		if (MD_NodeIsNil(funcNode)) {
			break;
		}

		ParseFuncResult res = ParseFunc(funcNode);
		if (res.Error) {
			return res.Error;
		}

		MD_String8 cppClassName = MD_TagFromString(primaryClassNode, MD_S8Lit("class"), 0)->first_child->string;

		GenOutputOptions genOptions = (GenOutputOptions){
			.ParsedFunction = res, // TODO: better name
			.LuaClassName = primaryClassNode->string,
			.CppClassName = cppClassName,
			.FunctionName = res.Name, // TODO: way better name please
			.IsStatic = MD_NodeHasTag(funcNode, MD_S8Lit("static"), 0),
			.SkipLuaWrapper = MD_NodeHasTag(funcNode, MD_S8Lit("nolua"), 0),
		};

		if (MD_NodeHasTag(funcNode, MD_S8Lit("constructor"), 0)) {
			genOptions.IsConstructor = 1;
			genOptions.CustomCppReturnType = MD_S8Lit("void*");
			genOptions.CustomCppBody = MD_S8Fmt(a,
				"    return new %S(%S);",
				cppClassName, MD_S8ListJoin(a, GenCppCallArgs(res), &commaJoin)
			);
			genOptions.CustomLuaBody = MD_S8Fmt(a,
				"    local instance = {\n"
				"        _this = ffi.C.%S(%S),\n"
				"    }\n"
				"    setmetatable(instance, self)\n"
				"    self.__index = self\n"
				"    return instance",
				GenMethodName(genOptions.LuaClassName, genOptions.FunctionName), MD_S8ListJoin(a, GenLuaCallArgs(res, 0), &commaJoin)
			);
		} else if (MD_NodeHasTag(funcNode, MD_S8Lit("converter"), 0)) {
			genOptions.CustomCppReturnType = MD_S8Lit("void*");

			MD_String8 convertTo = MD_TagFromString(funcNode, MD_S8Lit("converter"), 0)->first_child->string;
			genOptions.CustomCppBody = MD_S8Fmt(a,
				"    %S* _converted = (%S*)_this;\n"
				"    return _converted;",
				convertTo, cppClassName
			);
		} else {
			MD_String8 cppFunc = res.Name;
			MD_Node* aliasTag = MD_TagFromString(funcNode, MD_S8Lit("alias"), 0);
			if (!MD_NodeIsNil(aliasTag)) {
				cppFunc = aliasTag->first_child->string;
			}
		}

		GenOutputResult genRes = GenOutput(genOptions);
		MD_S8ListPush(a, cppDefs, genRes.CppFunction);
		MD_S8ListPush(a, luaSignatures, genRes.LuaBindingSignature);
		MD_S8ListPush(a, luaDefs, genRes.LuaFunction);

		funcNode = res.After;
	}

	return NULL;
}

MD_Message* GenEnum(ParseEnumResult enm, MD_String8List* cppDefs, MD_String8List* luaDefs) {
	MD_String8List values = {0};
	MD_String8List valueTypes = {0};

	for (int i = 0; i < enm.NumValues; i++) {
		MD_S8ListPushFmt(a, &values,
			"    %S = %d,",
			enm.ValueNames[i], enm.ValueNums[i]
		);
		MD_S8ListPushFmt(a, &valueTypes,
			"---@field %S integer",
			enm.ValueNames[i]
		);
	}

	MD_S8ListPushFmt(a, luaDefs,
		"---@class %S\n"
		"%S\n"
		"%S = BindingEnum:new('%S', {\n"
		"%S\n"
		"})\n",
		enm.Name,
		MD_S8ListJoin(a, valueTypes, &newlineJoin),
		enm.Name, enm.Name,
		MD_S8ListJoin(a, values, &newlineJoin)
	);

	return NULL;
}

void PrintMessage(FILE* file, MD_Message* m) {
	MD_CodeLoc loc = MD_ZERO_STRUCT;
	if (m->node) {
		loc = MD_CodeLocFromNode(m->node);
	}
	MD_PrintMessage(file, loc, m->kind, m->string);
}

void PrintMessages(FILE* file, MD_Message* first) {
	if (!first) {
		return;
	}
	for (MD_Message* m = first; m; m = m->next) {
		PrintMessage(file, m);
	}
}

void PrintMessageList(FILE* file, MD_MessageList messages) {
	PrintMessages(file, messages.first);
}

int main(int argc, char** argv) {
	a = MD_ArenaAlloc();
	newlineJoin.mid = MD_S8Lit("\n");
	commaJoin.mid = MD_S8Lit(", ");

	MD_ParseResult parse = MD_ParseWholeFile(a, MD_S8Lit("src/bindings/bindings.metadesk"));

	PrintMessageList(stderr, parse.errors);
	if (parse.errors.max_message_kind >= MD_MessageKind_Error) {
		return 1;
	}

	// DumpNode(parse.node);

	char filename_buf[128];
	MD_String8List luaSignatures = {0};

	for (MD_EachNode(f, parse.node->first_child)) {
		fprintf(stderr, "Processing file \"%.*s\"...\n", MD_S8VArg(f->string));

		sprintf(filename_buf, "src/main/cpp/wpiliblua/%.*s.cpp", MD_S8VArg(f->string));
		FILE* cppfile = fopen(filename_buf, "w");

		sprintf(filename_buf, "src/lua/wpilib/%.*s.lua", MD_S8VArg(f->string));
		FILE* luafile = fopen(filename_buf, "w");

		fprintf(cppfile, "// Automatically generated by bindings.c. DO NOT EDIT.\n\n");

		fprintf(luafile, "-- Automatically generated by bindings.c. DO NOT EDIT.\n");
		fprintf(luafile, "\n");
		fprintf(luafile, "local ffi = require(\"ffi\")\n");
		fprintf(luafile, "require(\"wpilib.bindings.asserts\")\n");
		fprintf(luafile, "require(\"wpilib.bindings.enum\")\n");
		fprintf(luafile, "\n");

		for (MD_EachNode(tag, f->first_tag)) {
			if (MD_S8Match(tag->string, MD_S8Lit("include"), 0)) {
				fprintf(cppfile, "#include %.*s\n", MD_S8VArg(tag->first_child->string));
			} else {
				fclose(cppfile);
				fclose(luafile);
				PrintMessage(stderr, &(MD_Message) {
					.node = tag,
						.kind = MD_MessageKind_Error,
						.string = MD_S8Fmt(a, "Unrecognized tag \"%S\" on file", tag->string),
				});
				return 1;
			}
		}
		fprintf(cppfile, "\n");

		fprintf(cppfile, "#include \"luadef.h\"\n\n");

		int numBaseClasses = 0;
		MD_Node* baseClasses[MAX_BASE_CLASSES] = {0};

		MD_String8List cppDefs = {0};
		MD_String8List luaDefs = {0};

		MD_Node* fentry = f->first_child;
		while (1) {
			if (MD_NodeIsNil(fentry)) {
				break;
			}

			if (MD_NodeHasTag(fentry, MD_S8Lit("baseclass"), 0)) {
				// Base class (save node for later lookup)
				baseClasses[numBaseClasses] = fentry;
				numBaseClasses++;
				fentry = fentry->next;
			} else if (MD_NodeHasTag(fentry, MD_S8Lit("class"), 0)) {
				// Class definition

				MD_String8 cppName = MD_TagFromString(fentry, MD_S8Lit("class"), 0)->first_child->string;
				MD_String8 luaName = fentry->string;

				fprintf(luafile, "---@class %.*s\n", MD_S8VArg(luaName));
				fprintf(luafile, "---@field _this %.*s\n", MD_S8VArg(luaName));
				fprintf(luafile, "%.*s = {}\n", MD_S8VArg(luaName));
				fprintf(luafile, "\n");

				for (MD_EachNode(tag, fentry->first_tag)) {
					if (!MD_S8Match(tag->string, MD_S8Lit("extends"), 0)) {
						continue;
					}

					// Look up base class
					MD_String8 baseClassName = tag->first_child->string;
					MD_Node* baseClass = 0;
					for (int i = 0; i < numBaseClasses; i++) {
						if (MD_S8Match(baseClasses[i]->string, baseClassName, 0)) {
							baseClass = baseClasses[i];
							break;
						}
					}
					if (!baseClass) {
						fclose(cppfile);
						fclose(luafile);
						MD_PrintMessageFmt(stderr, MD_CodeLocFromNode(tag), MD_MessageKind_Error,
							"Couldn't find base class \"%S\"",
							baseClassName
						);
						return 1;
					}

					MD_Message* error = addClassFuncs(baseClass, fentry, &cppDefs, &luaSignatures, &luaDefs);
					if (error) {
						fclose(cppfile);
						fclose(luafile);
						MD_Message* msg = &(MD_Message) {
							.next = error,
								.node = tag,
								.kind = MD_MessageKind_Error,
								.string = MD_S8Fmt(a, "Failed to add functions from base class \"%S\"", baseClassName),
						};
						PrintMessages(stderr, msg);
						return 1;
					}
				}

				MD_Message* error = addClassFuncs(fentry, fentry, &cppDefs, &luaSignatures, &luaDefs);
				if (error) {
					fclose(cppfile);
					fclose(luafile);
					MD_Message* msg = &(MD_Message) {
						.next = error,
							.node = fentry,
							.kind = MD_MessageKind_Error,
							.string = MD_S8Fmt(a, "Failed to add functions for class \"%S\"", luaName),
					};
					PrintMessages(stderr, msg);
					return 1;
				}

				fentry = fentry->next;
			} else if (MD_NodeHasTag(fentry, MD_S8Lit("enum"), 0)) {
				// Enum definition

				ParseEnumResult res = ParseEnum(fentry);
				if (res.Error) {
					fclose(cppfile);
					fclose(luafile);
					PrintMessage(stderr, res.Error);
					return 1;
				}

				MD_Message* error = GenEnum(res, &cppDefs, &luaDefs);
				if (error) {
					fclose(cppfile);
					fclose(luafile);
					PrintMessage(stderr, error);
					return 1;
				}

				fentry = fentry->next;
			} else if (MD_NodeHasTag(fentry, MD_S8Lit("struct"), 0)) {
				ParseStructResult res = ParseStruct(fentry);

				MD_String8 genRes = GenStruct(res);

				MD_S8ListPush(a, &cppDefs, genRes);
				MD_S8ListPush(a, &luaSignatures, genRes);

				fentry = fentry->next;
			} else {
				// Plain old function

				ParseFuncResult res = ParseFunc(fentry);
				if (res.Error) {
					fclose(cppfile);
					fclose(luafile);
					PrintMessage(stderr, res.Error);
					return 1;
				}

				// TODO: actually support these
				// GenFuncResult genRes = GenFunc(res, MD_S8Lit(""), MD_S8Lit(""), MD_S8Lit(""), MD_S8Lit(""), 0);
				// MD_S8ListPush(a, &cppDefs, genRes.CppDef);
				// MD_S8ListPush(a, &luaSignatures, genRes.LuaDef);

				GenOutputResult genRes = GenOutput((GenOutputOptions) {
					.ParsedFunction = res,
						.FunctionName = res.Name,
						// .IsStatic = true,
						.SkipLuaWrapper = MD_NodeHasTag(fentry, MD_S8Lit("nolua"), 0),
				});
				MD_S8ListPush(a, &cppDefs, genRes.CppFunction);
				MD_S8ListPush(a, &luaSignatures, genRes.LuaBindingSignature);
				MD_S8ListPush(a, &luaDefs, genRes.LuaFunction);

				fentry = res.After;
			}
		}

		fprintf(cppfile, "%.*s", MD_S8VArg(MD_S8ListJoin(a, cppDefs, &newlineJoin)));
		fclose(cppfile);

		fprintf(luafile, "%.*s", MD_S8VArg(MD_S8ListJoin(a, luaDefs, &newlineJoin)));
		fclose(luafile);
	}

	// Output Lua FFI bindings
	FILE* luafile = fopen("src/lua/wpilib/bindings/init.lua", "w");
	fprintf(luafile,
		"-- Automatically generated by bindings.c. DO NOT EDIT.\n"
		"\n"
		"local ffi = require(\"ffi\")\n"
		"ffi.cdef[[\n"
		"%.*s\n"
		"]]\n",
		MD_S8VArg(MD_S8ListJoin(a, luaSignatures, &newlineJoin))
	);
	fclose(luafile);

	return 0;
}
