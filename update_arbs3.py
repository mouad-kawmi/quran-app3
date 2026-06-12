import json

keys = {
  "adhanEnabled": {"en": "Adhan enabled", "fr": "Adhan activé", "ar": "الأذان مفعّل"},
  "adhanDisabled": {"en": "Adhan disabled", "fr": "Adhan désactivé", "ar": "الأذان غير مفعّل"},
  "stopPreview": {"en": "Stop preview", "fr": "Arrêter l'aperçu", "ar": "إيقاف المعاينة"},
  "listenAdhan": {"en": "Listen to Adhan", "fr": "Écouter l'Adhan", "ar": "استماع للأذان"},
  "adhanAttribution": {"en": "Adhan audio from Wikimedia Commons under CC BY-SA 4.0: Andrewler and Atcovi.", "fr": "Sons d'Adhan de Wikimedia Commons sous licence CC BY-SA 4.0 : Andrewler et Atcovi.", "ar": "أصوات الأذان من Wikimedia Commons تحت رخصة CC BY-SA 4.0: Andrewler و Atcovi."}
}

base_path = "lib/l10n/"
langs = ["en", "fr", "ar"]

for lang in langs:
    file_path = f"{base_path}app_{lang}.arb"
    with open(file_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    for key, val in keys.items():
        data[key] = val[lang]
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

print("Done!")
