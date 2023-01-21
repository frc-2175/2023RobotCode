#include "httpserver.h"

#include <cstdio>
#include <iostream>
#include <fstream>
#include <vector>
#include <regex>

#include "fmt/format.h"
#include "wpinet/EventLoopRunner.h"
#include "wpinet/HttpServerConnection.h"
#include "wpinet/UrlParser.h"
#include "wpinet/uv/Loop.h"
#include "wpinet/uv/Tcp.h"
#include "frc/Filesystem.h"
#include "frc/RobotBase.h"
#include "filesystem.hpp"

namespace fs = ghc::filesystem;
namespace uv = wpi::uv;

std::string deployPath()
{
	if (frc::RobotBase::IsReal())
	{
		return (std::string) "/home/lvuser/deploy/logViewer";
	}
	else
	{
		return frc::filesystem::GetDeployDirectory() + "/logViewer";
	}
}

std::string readFile(std::string path)
{
	FILE *file = fopen((path).c_str(), "r");

	if (!file)
	{
		return "File not found";
	}

	// get file size
	fseek(file, 0, SEEK_END);
	long stringlength = ftell(file);

	// read file to string.
	std::string fileText(stringlength, '\0');
	fseek(file, 0, SEEK_SET);
	fread(&fileText[0], sizeof(char), (size_t)stringlength, file);
	std::cout << fileText;
	fclose(file);

	return fileText;
}

class MyHttpServerConnection : public wpi::HttpServerConnection
{
public:
	explicit MyHttpServerConnection(std::shared_ptr<uv::Stream> stream)
		: HttpServerConnection(stream)
	{
	}

protected:
	void ProcessRequest() override;
};

void MyHttpServerConnection::ProcessRequest()
{
	fmt::print(stderr, "HTTP request: '{}'\n", m_request.GetUrl());
	wpi::UrlParser url{m_request.GetUrl(),
					   m_request.GetMethod() == wpi::HTTP_CONNECT};
	if (!url.IsValid())
	{
		// failed to parse URL
		SendError(400);
		return;
	}

	std::string_view path;
	if (url.HasPath())
	{
		path = url.GetPath();
	}

	std::string_view query;
	if (url.HasQuery())
	{
		query = url.GetQuery();
	}

	fs::path logDir("/home/lvuser/logs/");
	fs::directory_iterator logIterator(logDir);

	std::string fileList;

	for (const auto &entry : logIterator)
		fileList += entry.path().filename().generic_string() + "\\n";

	const bool isGET = m_request.GetMethod() == wpi::HTTP_GET;
	if (isGET)
	{
		if (path == "/")
		{
			// build HTML root page
			std::string logViewer = readFile(frc::filesystem::GetDeployDirectory() + (std::string) "/logViewer/index.html");

			SendResponse(200, "OK", "text/html", logViewer);
		}
		else if (path == "/logs")
		{
			SendResponse(200, "OK", "text/plain", fileList);
		}
		else if (path.rfind("/logs/", 0) == 0)
		{
			// mhm yeah oh yeah boogy!!!.
			std::string logFile = readFile("/home/lvuser" + (std::string)path);

			SendResponse(200, "OK", "application/json", logFile);
		}
		else if (path == "/normalize.css")
		{
			std::string css = readFile(frc::filesystem::GetDeployDirectory() + (std::string) "/logViewer/normalize.css");

			SendResponse(200, "OK", "text/css", css);
		}
		else if (path == "/script.js")
		{
			std::string js = readFile(frc::filesystem::GetDeployDirectory() + (std::string) "/logViewer/script.js");

			SendResponse(200, "OK", "text/javascript", js);
		}
	}
	else
	{
		SendError(404, "Resource not found");
	}
}

wpi::EventLoopRunner loop;

void StartHTTPServer()
{
	// Kick off the event loop on a separate thread
	loop.ExecAsync([](uv::Loop &loop)
				   {
    auto tcp = uv::Tcp::Create(loop);

    auto printErrors = [](uv::Error err) {
      fmt::print(stderr, "SERVER ERROR: ({} {}) {}\n", err.code(), err.name(), err.str());
    };
    tcp->error.connect(printErrors);

    // bind to listen address and port
    tcp->Bind("", 5800);

    // when we get a connection, accept it and start reading
    tcp->connection.connect([srv = tcp.get()]{
      auto tcp = srv->Accept();
      if (!tcp) {
        return;
      }
      auto conn = std::make_shared<MyHttpServerConnection>(tcp);
      tcp->SetData(conn);
    });

    // start listening for incoming connections
    tcp->Listen();

    std::fputs("Listening on port 2175\n", stderr); });
}