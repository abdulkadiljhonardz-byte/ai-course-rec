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

### Website

Ang website ay Flutter web build ng mismong app, kaya pareho ang design,
screens, navigation, at recommendation flow ng mobile version.

```bash
flutter run -d chrome
```

Ang production files para sa GitHub Pages ay nasa `docs/` at maaaring buuin
ulit gamit ang:

```bash
flutter build web --release \
  --base-href /ai-course-rec/ \
  --output docs \
  --dart-define=GROQ_API_URL=https://ai-course-rec-production.up.railway.app/api/recommend
```

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

Pagkatapos i-save ang file, gamitin ito bilang compile-time configuration:

```bash
flutter run --dart-define-from-file=secrets.json
```

Hindi kasama ang `secrets.json` sa app assets o public web build. Kapag walang
AI configuration, automatic na gagamitin ng app ang local scoring engine.

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

## Secure Railway Web Deployment

Ang Railway deployment ang nagse-serve ng Flutter website at ng secure
`/api/recommend` Groq proxy. Ang `GROQ_API_KEY` ay Railway service variable at
hindi kasama sa GitHub o compiled website.

```bash
flutter build web --release \
  --base-href / \
  --output railway/public \
  --dart-define=GROQ_API_URL=/api/recommend

cd railway
npm test
railway up
```

Live Railway site: `https://ai-course-rec-production.up.railway.app/`

## Notes

- Ang recommendations ay ranking guide lamang at hindi final admission result.
- Mas kumpleto ang input, mas magiging kapaki-pakinabang ang recommendation output.
- Hindi ipinapadala sa AI API ang pangalan ng student; assessment profile at
  course catalog lang ang kasama sa ranking request.
