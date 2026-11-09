import processing.core.PApplet;

public final class ProcessingWebLauncher {

    public static void main(String[] args) {
        String sketchPath = args.length > 0
            ? args[0]
            : "/app/works/demo/v1";

        PApplet.main(new String[] {
            "--sketch-path=" + sketchPath,
            "ProcessingSmokeTest"
        });
    }
}