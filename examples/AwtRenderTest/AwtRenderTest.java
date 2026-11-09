import java.awt.*;
import java.awt.image.BufferedImage;
import java.awt.image.BufferStrategy;

public class AwtRenderTest {

    static BufferedImage createTestImage() {
        BufferedImage image = new BufferedImage(
            320, 320, BufferedImage.TYPE_INT_ARGB
        );

        Graphics2D g = image.createGraphics();

        g.setColor(new Color(30, 140, 80));
        g.fillRect(0, 0, 320, 320);

        g.setColor(Color.WHITE);
        g.drawString("BufferedImage", 20, 40);

        g.setColor(Color.YELLOW);
        g.fillOval(80, 90, 120, 120);

        g.dispose();

        return image;
    }

    // 通常のCanvas.paint()で画像を直接描画する
    static class DirectCanvas extends Canvas {
        private final BufferedImage image;

        DirectCanvas(BufferedImage image) {
            this.image = image;
        }

        @Override
        public void paint(Graphics g) {
            g.setColor(new Color(190, 40, 50));
            g.fillRect(0, 0, getWidth(), getHeight());

            g.drawImage(
                image,
                20, 40,
                getWidth() - 40,
                getHeight() - 80,
                null
            );
        }

        @Override
        public void update(Graphics g) {
            paint(g);
        }
    }

    public static void main(String[] args) {
        EventQueue.invokeLater(() -> {
            BufferedImage image = createTestImage();

            Frame frame = new Frame("AWT BufferedImage Test");

            frame.setLayout(new GridLayout(1, 2));

            DirectCanvas directCanvas = new DirectCanvas(image);
            Canvas bufferedCanvas = new Canvas();

            frame.add(directCanvas);
            frame.add(bufferedCanvas);

            frame.setSize(720, 420);
            frame.setVisible(true);

            directCanvas.repaint();

            String stage = "before createBufferStrategy";

        try {
            System.out.println(
                "Canvas displayable: " + bufferedCanvas.isDisplayable()
            );

            System.out.println(
                "Canvas showing: " + bufferedCanvas.isShowing()
            );

            System.out.println(
                "Canvas size: " +
                bufferedCanvas.getWidth() + "x" +
                bufferedCanvas.getHeight()
            );

            stage = "createBufferStrategy";

            bufferedCanvas.createBufferStrategy(2);

            stage = "getBufferStrategy";

            BufferStrategy strategy =
                bufferedCanvas.getBufferStrategy();

            if (strategy == null) {
                frame.setTitle("RESULT: BufferStrategy is NULL");
                System.err.println(
                    "getBufferStrategy() returned null."
                );
                return;
            }

            stage = "getDrawGraphics";

            Graphics2D g =
                (Graphics2D) strategy.getDrawGraphics();

            if (g == null) {
                frame.setTitle("RESULT: DrawGraphics is NULL");
                return;
            }

            stage = "drawImage";

            try {
                g.setColor(Color.GRAY);

                g.fillRect(
                    0, 0,
                    bufferedCanvas.getWidth(),
                    bufferedCanvas.getHeight()
                );

                g.drawImage(
                    image,
                    20, 40,
                    bufferedCanvas.getWidth() - 40,
                    bufferedCanvas.getHeight() - 80,
                    null
                );
            } finally {
                g.dispose();
            }

            stage = "show";

            strategy.show();

            frame.setTitle("RESULT: BufferStrategy works");

        } catch (Throwable error) {
            frame.setTitle(
                "FAILED at " + stage + ": " +
                error.getClass().getSimpleName()
            );

            error.printStackTrace();
        }
        });
    }
}