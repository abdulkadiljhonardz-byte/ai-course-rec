# MSU-Sulu Course Guide

Flutter app ito para magbigay ng ranked course recommendations base sa grades,
interest, at self-assessment ng student.

## User Flow

Step by step ang proseso sa app:

1. Pumunta sa `Recommend` tab.
2. Ilagay ang pangalan ng student.
3. I-enter ang `Math`, `Science`, at `English` grades.
4. Optional lang ang `CET` score, pero puwedeng idagdag para mas refined ang result.
5. Piliin ang pinaka-akmang interest area.
6. Sagutan ang strengths, skills, at weaknesses para mas personalized ang matching.
7. Pindutin ang `Generate Recommendation`.
8. I-review ang ranked results at top match sa results screen.
9. Kung gusto mong baguhin ang sagot, bumalik sa form at mag-generate ulit.

## Main Screens

- `Recommend`: guided step-by-step input form
- `Courses`: listahan ng available courses
- `History`: previous recommendation sessions

## Run Locally

### Website (pinakamabilis)

May standalone website sa root `index.html`. Wala itong kailangang package o
API key; browser-local scoring engine at `localStorage` ang gamit nito.

```bash
python3 -m http.server 8080 --bind 127.0.0.1
```

Pagkatapos, buksan ang `http://localhost:8080`. Para i-deploy, i-upload ang
`index.html`, `manifest.webmanifest`, at `web/` folder sa anumang static host
tulad ng GitHub Pages, Netlify, o Cloudflare Pages. Huwag isama ang
`secrets.json` sa anumang public deployment.

### Flutter app

1. Install Flutter SDK.
2. Sa project folder, patakbuhin ang `flutter pub get`.
3. I-run ang app gamit ang `flutter run`.

## AI API Setup

Kapag may AI configuration, ginagamit ng app ang Groq Responses API para
i-rerank ang courses at gumawa ng personalized reasons at improvement areas.
Kapag walang configuration o pumalya ang request, automatic itong gumagamit ng
existing local scoring engine.

Para sa local prototype, ilagay ang bagong Groq key sa ignored na
`secrets.json` file:

```json
{
  "GROQ_API_KEY": "PASTE_NEW_GROQ_KEY_HERE",
  "GROQ_MODEL": "openai/gpt-oss-20b"
}
```

Pagkatapos i-save ang file, puwede nang gamitin ang normal Flutter command:

```bash
flutter run
```

Ilo-load ng app ang `secrets.json` bago gumawa ng recommendation engine. Ang
`--dart-define-from-file=secrets.json` ay supported pa rin bilang optional
override, pero hindi na ito kailangan para sa local school-project build.

Huwag gamitin ang direct API key setup sa production build. Ang
`--dart-define` value ay maaaring ma-extract mula sa compiled Flutter app.
Gumamit ng backend proxy na nagtatago ng Groq key, saka ituro rito ang app:

```bash
flutter run \
  --dart-define=GROQ_API_URL=https://your-server.example/v1/responses
```

Ang proxy endpoint ay dapat tumanggap ng Groq Responses API request body at
magbalik ng kaparehong response shape. Sa Android release, naka-enable na ang
internet permission.

## Notes

- Ang recommendations ay ranking guide lamang at hindi final admission result.
- Mas kumpleto ang input, mas magiging kapaki-pakinabang ang recommendation output.
- Hindi ipinapadala sa AI API ang pangalan ng student; assessment profile at
  course catalog lang ang kasama sa ranking request.
