#!/bin/bash

declare -a arr=("Amharic" "Armenian" "Bashkir" "Bhojpuri" "Breton" "Burmese"
	"Catalan" "Chuvash" "Czech" "Danish" "Estonian" "Finnish" "French" "Georgian"
	"German" "Gujarati" "Hausa" "Hungarian" "Indonesian" "Irish" "Japanese" "Kabyle"
	"Kannada" "Karachay-Balkar" "Korean" "Lao" "Latvian" "Lezgian" "Lithuanian"
	"Maithili" "Malayalam" "Maori" "Marathi" "Ossetian" "Polish" "Romanian"
	"Romansh" "Sakha" "Samoan" "Somali" "Sundanese" "Swahili" "Tajik" "Tamil"
	"Tatar" "Telugu" "Tetum" "Thai" "Tulu" "Turkish" "Turkmen" "Welsh" "Yoruba")

declare -a fullarr=("Basque" "Dutch" "Alemannic" "Wolof" "Bosnian" "Hindi"
	"Danish" "Russian" "Urdu" "German" "Swedish" "Afrikaans" "Anglo-Saxon"
	"Icelandic" "Belarusian" "Bulgarian" "Croatian" "Macedonian" "Serbo-Croatian"
	"Ukrainian" "Vietnamese" "Pangasinan" "Kapampangan" "Khmer" "Japanese"
	"Javanese" "Indonesian" "Polish" "Malay" "Sundanese" "Hakka" "Turkish"
	"Kazakh" "Kirghiz" "Turkmen" "Hebrew" "Persian" "Arabic" "Tajik" "Latin"
	"French" "Galician" "Romanian" "Norman" "Corsican" "Maori" "Nepali" "Mongolian"
	"Estonian" "Finnish" "Hungarian" "Bengali" "Waray" "Welsh" "Armenian" "Korean"
	"Greek" "Catalan" "Walloon" "Yiddish" "Maltese" "Romansh" "Bavarian" "Faroese"
	"Ripuarian" "Luxembourgish" "Limburgish" "Scots" "Zeelandic" "Aragonese"
	"Asturian" "Emilian-Romagnol" "Extremaduran" "Franco-Provençal" "Friulian"
	"Ladino" "Lombard" "Mirandese" "Neapolitan" "Occitan" "Picard" "Sardinian"
	"Sicilian" "Venetian" "Czech" "Rusyn" "Slovenian" "Serbian" "Slovak"
	"Silesian" "Acehnese" "Banyumasan" "Wu" "Azerbaijani" "Bashkir" "Chuvash"
	"Gagauz" "Karachay-Balkar" "Sakha" "Tatar" "Uyghur" "Uzbek" "Amharic" "Zazaki"
	"Gilaki" "Mazandarani" "Ossetian" "Pashto" "Võro" "Komi" "Vepsian" "Erzya"
	"Assamese" "Bhojpuri" "Divehi" "Konkani" "Gujarati" "Marathi" "Odia"
	"Maithili" "Sanskrit" "Sindhi" "Sinhalese" "Esperanto" "Interlingua"
	"Interlingue" "Ido" "Lithuanian" "Latvian" "Samogitian" "Kannada" "Malayalam"
	"Tamil" "Telugu" "Breton" "Irish" "Manx" "Burmese" "Georgian" "Mingrelian"
	"Lao" "Thai" "Lezgian" "Malagasy" "Papiamentu" "Chavacano" "Albanian"
	"Luganda" "Swahili" "Tswana" "Tsonga" "Yoruba" "Quechua" "Buryat" "Samoan"
	"Tongan" "Nahuatl" "Somali" "Aymara" "Guarani" "Kabyle" "Hausa" "Tetum"
	"Tulu" "Kabiye")

for i in "${arr[@]}"
do
  Rscript wiki_relative_surprisal.R "$i" $1
done
