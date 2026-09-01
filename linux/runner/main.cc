#include <webview_cef/webview_cef_plugin.h>
#include "my_application.h"

int main(int argc, char** argv) {
  // CEF is multi-process and re-executes this same binary as its renderer, GPU
  // and utility processes, so `main` has to answer for one of those before it
  // decides it is the application. A non-negative code means this invocation
  // was a CEF child that has finished; the Flutter application below is never
  // constructed in that case.
  //
  // These four lines and the two in my_application.cc are written by
  // webview_cef's CMake step, which patches this file during a build. They are
  // committed so that the patch is a diff somebody reviewed rather than a
  // mutation of tracked sources that happens behind the build; the scripts that
  // write them are guarded by greps, so this is a no-op for them.
  // `docs/architecture.md` carries the argument, and `lib/data/services/epub`
  // is what needs it.
  int exit_code = initCEFProcesses(argc, argv);
  if (exit_code >= 0) {
    return exit_code;
  }
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
