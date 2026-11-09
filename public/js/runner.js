const startButton = document.querySelector("#startButton");
const reloadButton = document.querySelector("#reloadButton");
const statusTitle = document.querySelector("#statusTitle");
const statusLog = document.querySelector("#statusLog");
const displayHost = document.querySelector("#displayHost");

const SKETCH_CLASS = "ProcessingWebLauncher";

const SKETCH_CLASSPATH = [
  "/app/lib/processing-awt-patch-4.5.7.jar",
  "/app/ProcessingWebLauncher-4.5.7.jar",
  "/app/works/demo/v4.5.7/ProcessingSmokeTest.jar",
  "/app/lib/processing-core-4.5.7.jar"
].join(":");

const SKETCH_PATH = "/app/works/demo/v4.5.7";

let isRunning = false;
let hasStarted = false;

function setStatus(title, message) {
  statusTitle.textContent = title;
  statusLog.textContent = message;
}

function clearDisplay() {
  displayHost.replaceChildren();
  const placeholder = document.createElement("p");
  placeholder.className = "placeholder";
  placeholder.textContent = "起動中、または実行待機中です。";
  displayHost.append(placeholder);
}

async function startSketch() {
  if (isRunning || hasStarted) return;

  isRunning = true;
  startButton.disabled = true;
  clearDisplay();
  setStatus("CheerpJを初期化中", "Java 17 runtimeを初期化しています。初回はランタイムの取得に時間がかかる場合があります。");

  try {
    if (typeof window.cheerpjInit !== "function") {
      throw new Error("CheerpJ loaderが読み込まれていません。ネットワーク/CSP/loader.jsを確認してください。");
    }

    await window.cheerpjInit({ version: 17 });
    setStatus("Processingを起動中", `Class: ${SKETCH_CLASS}\nClasspath: ${SKETCH_CLASSPATH}\nSketch path: ${SKETCH_PATH}`);

    // Remove the loading placeholder before CheerpJ appends its display element.
    displayHost.replaceChildren();
    window.cheerpjCreateDisplay(720, 420, displayHost);

    const exitCode = await window.cheerpjRunMain(
      SKETCH_CLASS,
      SKETCH_CLASSPATH,
      SKETCH_PATH
    );

    hasStarted = exitCode === 0;
    if (exitCode === 0) {
      setStatus(
        "Java main() の起動処理が正常終了しました（exit code: 0）",
        "Processingのdraw()が継続しているか、表示領域を確認してください。PApplet.main()が起動後に戻る構成でも、描画スレッドは継続する場合があります。停止・再起動はページ再読み込みで行います。"
      );
    } else {
      setStatus(
        `Java main() が異常終了しました（exit code: ${exitCode}）`,
        "Consoleの例外とクラスパス、Processing Core JARの配置を確認してください。"
      );
    }
  } catch (error) {
    hasStarted = false;
    console.error(error);
    setStatus("起動に失敗しました", `${error?.stack || error}`);
  } finally {
    startButton.disabled = hasStarted;
    isRunning = false;
  }
}

startButton.addEventListener("click", startSketch);
reloadButton.addEventListener("click", () => window.location.reload());
