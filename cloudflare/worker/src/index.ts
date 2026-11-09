interface Env {
  WORKS_BUCKET: R2Bucket;
  ASSETS: Fetcher;
}

function badRequest(message: string): Response {
  return new Response(message, {
    status: 400,
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
}

function contentTypeFromPath(path: string): string {
  const extension = path.split(".").pop()?.toLowerCase();
  const types: Record<string, string> = {
    css: "text/css; charset=utf-8",
    csv: "text/csv; charset=utf-8",
    gif: "image/gif",
    html: "text/html; charset=utf-8",
    jpeg: "image/jpeg",
    jpg: "image/jpeg",
    js: "text/javascript; charset=utf-8",
    json: "application/json; charset=utf-8",
    mp3: "audio/mpeg",
    mp4: "video/mp4",
    obj: "text/plain; charset=utf-8",
    ogg: "audio/ogg",
    otf: "font/otf",
    pdf: "application/pdf",
    png: "image/png",
    svg: "image/svg+xml",
    txt: "text/plain; charset=utf-8",
    wav: "audio/wav",
    webm: "video/webm",
    webp: "image/webp",
    woff: "font/woff",
    woff2: "font/woff2",
    vlw: "application/octet-stream",
    jar: "application/java-archive",
  };
  return (extension && types[extension]) || "application/octet-stream";
}

function getPublishedObjectKey(pathname: string): string | null {
  const prefix = "/works/";
  if (!pathname.startsWith(prefix)) return null;

  let relativePath: string;
  try {
    relativePath = decodeURIComponent(pathname.slice(prefix.length));
  } catch {
    return null;
  }

  const segments = relativePath.split("/");
  if (segments.length < 3) return null; // work ID / version / file path
  if (segments.some((part) => !part || part === "." || part === ".." || part.includes("\\") || part.includes("\0"))) {
    return null;
  }

  const [workId, version] = segments;
  if (!/^[A-Za-z0-9_-]{1,100}$/.test(workId)) return null;
  if (!/^[A-Za-z0-9._-]{1,100}$/.test(version)) return null;

  return `published/${relativePath}`;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // Everything except published work assets is served by Cloudflare Static Assets.
    if (!url.pathname.startsWith("/works/")) {
      return env.ASSETS.fetch(request);
    }

    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Method Not Allowed", {
        status: 405,
        headers: { Allow: "GET, HEAD" },
      });
    }

    const objectKey = getPublishedObjectKey(url.pathname);
    if (!objectKey) return badRequest("Invalid work asset path.");

    try {
      const object = request.method === "HEAD"
        ? await env.WORKS_BUCKET.head(objectKey)
        : await env.WORKS_BUCKET.get(objectKey, { range: request.headers });

      if (!object) {
        return new Response("Not Found", { status: 404 });
      }

      const headers = new Headers();
      object.writeHttpMetadata(headers);
      headers.set("ETag", object.httpEtag);
      headers.set("Accept-Ranges", "bytes");
      headers.set("X-Content-Type-Options", "nosniff");
      headers.set("Cache-Control", "public, max-age=31536000, immutable");

      if (!headers.has("Content-Type")) {
        headers.set("Content-Type", contentTypeFromPath(objectKey));
      }

      if (request.method === "HEAD") {
        headers.set("Content-Length", String(object.size));
        return new Response(null, { status: 200, headers });
      }

      if (!("body" in object)) {
        return new Response(null, { status: 304, headers });
      }

      if (object.range) {
        const requestedLength = object.range.length ?? object.range.suffix;
        const start = object.range.offset ?? (
          typeof requestedLength === "number"
            ? Math.max(0, object.size - requestedLength)
            : 0
        );
        const length = typeof object.range.length === "number"
          ? object.range.length
          : object.size - start;
        headers.set("Content-Range", `bytes ${start}-${start + length - 1}/${object.size}`);
        headers.set("Content-Length", String(length));
        return new Response(object.body, { status: 206, headers });
      }

      headers.set("Content-Length", String(object.size));
      return new Response(object.body, { status: 200, headers });
    } catch (error) {
      console.error("R2 asset read failed", error);
      return new Response("Asset delivery failed.", { status: 502 });
    }
  },
};
