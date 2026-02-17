# imgsqz

Tiny, dockerized image compression toolbox.
Bring best-of-breed encoders/optimizers to any project with one container.

> Ships a curated set of CLI tools (mozjpeg, jpegoptim, guetzli, optipng, pngcrush, advpng) and a lean runtime so you can batch-optimize images locally or in CI without installing native deps.

---

## Why

* **Consistent results anywhere** → same binaries on macOS, Linux, CI.
* **No native install pain** → everything runs inside a container.
* **Composable** → mix lossless & lossy steps per format.

---

## Acknowledgements

* The authors and maintainers of [**mozjpeg**](https://github.com/mozilla/mozjpeg), [**jpegoptim**](https://github.com/tjko/jpegoptim), [**guetzli**](https://github.com/google/guetzli), [**optipng**](https://sourceforge.net/projects/optipng), [**pngcrush**](https://github.com/glennrp/pmt), and [**advancecomp**](https://github.com/amadvance/advancecomp).
* Inspired by the need for a **portable**, **zero-install** image optimization toolkit for local use and CI.

---

## What's inside

Format | Primary tools                                           | Typical use
-------|---------------------------------------------------------|------------
JPEG   | `mozjpeg` (`cjpeg`/`jpegtran`), `jpegoptim`, `guetzli`* | High-quality lossy encode; progressive; metadata stripping; lossless transforms
PNG    | `optipng`, `pngcrush`, `advpng`                         | Lossless structural optimizations; brute-force parameter search; advanced recompression

* *Guetzli is very slow and mostly of historical interest; prefer mozjpeg for production.*

---

## Quick start

### Build the image

```bash
git clone https://github.com/flavioheleno/imgsqz
cd imgsqz
docker build -t imgsqz .
```

### Run it against your images

Mount your working directory into `/app`:

```bash
# List available tools inside the container
docker run --rm imgsqz sh -lc 'cjpeg -version || true; jpegtran -version || true; jpegoptim --version; optipng -v | head -n1; pngcrush -version | head -n1; advpng --version | head -n1'
```

---

## Common recipes

> All commands assume the current host directory is mounted at `/app`.

### JPEG: high-quality encode (mozjpeg)

```bash
# Re-encode a JPEG with mozjpeg (quality 80, progressive, trellis, DC scan)
docker run --rm -v "$PWD:/app" imgsqz \
  sh -lc 'cjpeg -quality 80 -progressive -tune-ssim -optimize -baseline -sample 1x1 -outfile /app/out.jpg /app/in.jpg'
```

### JPEG: lossless size reduction (jpegtran → jpegoptim)

```bash
# Normalize & strip metadata without re-encoding pixels
docker run --rm -v "$PWD:/app" imgsqz \
  sh -lc 'jpegtran -copy none -optimize -progressive /app/in.jpg > /app/tmp.jpg && \
          jpegoptim --strip-all --preserve --totals /app/tmp.jpg && \
          mv /app/tmp.jpg /app/out.jpg'
```

### PNG: exhaustive lossless optimization (optipng)

```bash
docker run --rm -v "$PWD:/app" imgsqz \
  sh -lc 'optipng -o7 -strip all -out /app/out.png /app/in.png'
```

### PNG: alternative pass (pngcrush)

```bash
docker run --rm -v "$PWD:/app" imgsqz \
  sh -lc 'pngcrush -rem alla -brute -reduce /app/in.png /app/out.png'
```

### PNG: advanced recompression (advpng)

```bash
docker run --rm -v "$PWD:/app" imgsqz \
  sh -lc 'cp /app/in.png /app/out.png && advpng -z4 /app/out.png'
```

### Batch a whole folder (recursive, keep structure)

```bash
# JPEGs: re-encode to mozjpeg q=78 keeping tree
docker run --rm -v "$PWD:/app" imgsqz \
  sh -lc 'find /app/src -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) -print0 | \
          xargs -0 -I{} sh -c '\'' \
            out="/app/dist/${0#/app/src/}"; mkdir -p "$(dirname "$out")"; \
            cjpeg -quality 78 -progressive -optimize -outfile "$out" "$0" \
          '\'' {}'
```

---

## License

This project is licensed under the [MIT License](LICENSE).
