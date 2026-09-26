using System.Diagnostics;

namespace MediaBridge;

internal static class LogReveal
{
    private const string FileName = "dynamic_island_debug.log";

    public static string Reveal(string dir)
    {
        try
        {
            if (string.IsNullOrEmpty(dir) || !Directory.Exists(dir)) return "no_dir";
            string file = Path.Combine(dir, FileName);
            var info = File.Exists(file)
                ? new ProcessStartInfo("explorer.exe", "/select,\"" + file + "\"")
                : new ProcessStartInfo("explorer.exe", "\"" + dir + "\"");
            info.UseShellExecute = false;
            Process.Start(info);
            return File.Exists(file) ? "ok" : "no_file";
        }
        catch
        {
            return "error";
        }
    }
}
