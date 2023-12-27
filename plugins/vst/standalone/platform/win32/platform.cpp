//-----------------------------------------------------------------------------
// Flags       : clang-format auto
// Project     : VST SDK
//
// Category    : StandaloneHost
// Filename    : public.sdk/samples/vst-hosting/editorhost/source/platform/win32/platform.cpp
// Created by  : Steinberg 09.2016
// Description : Example of opening a plug-in editor
//
//-----------------------------------------------------------------------------
// LICENSE
// (c) 2023, Steinberg Media Technologies GmbH, All Rights Reserved
//-----------------------------------------------------------------------------
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//   * Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//   * Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//   * Neither the name of the Steinberg Media Technologies nor the names of its
//     contributors may be used to endorse or promote products derived from this
//     software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
// OF THE POSSIBILITY OF SUCH DAMAGE.
//-----------------------------------------------------------------------------

#include "pluginterfaces/base/ftypes.h"
#include "platform/iplatform.h"
#include "platform/win32/window.h"
#include "public.sdk/source/vst/utility/stringconvert.h"

#include <windows.h>
#include <string>
#include <vector>
#include <algorithm>

//------------------------------------------------------------------------
namespace Steinberg {
namespace Vst {
namespace StandaloneHost {

//------------------------------------------------------------------------
class Platform : public IPlatform
{
public:
	static Platform& instance ()
	{
		static Platform gInstance;
		return gInstance;
	}

	void setApplication (ApplicationPtr&& app) override;
	WindowPtr createWindow (const std::string& title, Size size, bool resizeable,
	                        const WindowControllerPtr& controller) override;
	void quit () override;
	void kill (int resultCode, const std::string& reason) override;

	void run (LPWSTR lpCmdLine, HINSTANCE instance);

private:
	ApplicationPtr application;
	HINSTANCE hInstance {nullptr};
	bool quitRequested {false};
};

//------------------------------------------------------------------------
IPlatform& IPlatform::instance ()
{
	return Platform::instance ();
}

//------------------------------------------------------------------------
void Platform::setApplication (ApplicationPtr&& app)
{
	application = std::move (app);
}

//------------------------------------------------------------------------
WindowPtr Platform::createWindow (const std::string& title, Size size, bool resizeable,
                                  const WindowControllerPtr& controller)
{
	return Window::make (title, size, resizeable, controller, hInstance);
}

//------------------------------------------------------------------------
void Platform::quit ()
{
	if (quitRequested)
		return;
	quitRequested = true;

	for (auto& window : Window::getWindows ())
		window->closeImmediately ();

	if (application)
		application->terminate ();

	PostQuitMessage (0);
}

//------------------------------------------------------------------------
void Platform::kill (int resultCode, const std::string& reason)
{
	auto str = VST3::StringConvert::convert (reason);
	MessageBox (nullptr, reinterpret_cast<LPCWSTR> (str.data ()), nullptr, MB_OK);
	exit (resultCode);
}

//------------------------------------------------------------------------
void Platform::run (LPWSTR lpCmdLine, HINSTANCE _hInstance)
{
	hInstance = _hInstance;
	std::vector<std::string> cmdArgStrings;

        for (int i = 0; i < __argc; ++i)
	{
		cmdArgStrings.push_back (
                    VST3::StringConvert::convert (Steinberg::wscast (__wargv[i])));
        }

	auto noHIDPI = std::find (cmdArgStrings.begin (), cmdArgStrings.end (), "-noHIDPI");
	if (noHIDPI == cmdArgStrings.end ())
		ShcoreLibrary::instance ().setProcessDpiAwareness (true);

	application->init (cmdArgStrings);

	MSG msg;
	while (GetMessage (&msg, nullptr, 0, 0))
	{
		TranslateMessage (&msg);
		DispatchMessage (&msg);
	}
}

//------------------------------------------------------------------------
} // StandaloneHost
} // Vst
} // Steinberg

#ifndef _In_
#define _In_
#endif
#ifndef _In_opt_
#define _In_opt_
#endif

//------------------------------------------------------------------------
int APIENTRY wWinMain (_In_ HINSTANCE instance, _In_opt_ HINSTANCE /*prevInstance*/,
                       _In_ LPWSTR lpCmdLine, _In_ int /*nCmdShow*/)
{
	HRESULT hr = CoInitialize (nullptr);
	if (FAILED (hr))
		return FALSE;

        Steinberg::Vst::StandaloneHost::Platform::instance ().run (lpCmdLine, instance);

	CoUninitialize ();

	return 0;
}
