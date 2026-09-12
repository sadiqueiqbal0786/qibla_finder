import 'package:flutter/widgets.dart';

extension AppTranslation on BuildContext {
  String tr(String key) =>
      AppStrings.translate(key, Localizations.localeOf(this).languageCode);
}

class AppStrings {
  static String translate(String key, String language) {
    final values = _translations[key];
    if (values == null || language == 'en') return key;
    return values[language == 'ur' ? 1 : 0];
  }

  // English is the key; Hindi and Urdu are the initial additional languages.
  static const _translations = <String, List<String>>{
    'Qibla Finder': ['क़िबला फ़ाइंडर', 'قبلہ فائنڈر'],
    'Qibla': ['क़िबला', 'قبلہ'],
    'Qibla Compass': ['क़िबला कम्पास', 'قبلہ کمپاس'],
    'Prayer Times': ['नमाज़ के समय', 'نماز کے اوقات'],
    'Settings': ['सेटिंग्स', 'ترتیبات'],
    'Privacy policy': ['गोपनीयता नीति', 'رازداری کی پالیسی'],
    'Location': ['स्थान', 'مقام'],
    'Choose a city': ['शहर चुनें', 'شہر منتخب کریں'],
    'Search city': ['शहर खोजें', 'شہر تلاش کریں'],
    'Search': ['खोजें', 'تلاش کریں'],
    'Use device location': [
      'डिवाइस का स्थान उपयोग करें',
      'آلے کا مقام استعمال کریں',
    ],
    'Selected city': ['चुना हुआ शहर', 'منتخب شہر'],
    'Current location': ['वर्तमान स्थान', 'موجودہ مقام'],
    'Saved location': ['सहेजा गया स्थान', 'محفوظ مقام'],
    'Refresh location': ['स्थान अपडेट करें', 'مقام تازہ کریں'],
    'More': ['और', 'مزید'],
    'Today': ['आज', 'آج'],
    'Tomorrow': ['कल', 'کل'],
    'Previous day': ['पिछला दिन', 'پچھلا دن'],
    'Next day': ['अगला दिन', 'اگلا دن'],
    'Next prayer': ['अगली नमाज़', 'اگلی نماز'],
    'Time remaining': ['शेष समय', 'باقی وقت'],
    'Fajr': ['फ़ज्र', 'فجر'],
    'Sunrise': ['सूर्योदय', 'طلوع آفتاب'],
    'Dhuhr': ['ज़ुहर', 'ظہر'],
    'Jumma / Dhuhr': ['जुम्मा / ज़ुहर', 'جمعہ / ظہر'],
    'Asr': ['अस्र', 'عصر'],
    'Maghrib': ['मग़रिब', 'مغرب'],
    'Isha': ['इशा', 'عشاء'],
    'Calculation': ['गणना', 'حساب'],
    'Automatic': ['स्वचालित', 'خودکار'],
    'Manual': ['मैनुअल', 'دستی'],
    'Reminders': ['रिमाइंडर', 'یاد دہانیاں'],
    'Prayer reminders': ['नमाज़ के रिमाइंडर', 'نماز کی یاد دہانیاں'],
    'Remind me before prayer': [
      'नमाज़ से पहले याद दिलाएँ',
      'نماز سے پہلے یاد دلائیں',
    ],
    'At prayer time only': ['केवल नमाज़ के समय', 'صرف نماز کے وقت'],
    '5 minutes before': ['5 मिनट पहले', '5 منٹ پہلے'],
    '10 minutes before': ['10 मिनट पहले', '10 منٹ پہلے'],
    '15 minutes before': ['15 मिनट पहले', '15 منٹ پہلے'],
    '30 minutes before': ['30 मिनट पहले', '30 منٹ پہلے'],
    'Check reminders': ['रिमाइंडर जाँचें', 'یاد دہانیاں جانچیں'],
    'Send test notification': ['टेस्ट सूचना भेजें', 'آزمائشی اطلاع بھیجیں'],
    'Enable notifications': ['सूचनाएँ चालू करें', 'اطلاعات فعال کریں'],
    'Allow precise reminders': [
      'सटीक रिमाइंडर की अनुमति दें',
      'درست وقت کی یاد دہانی کی اجازت دیں',
    ],
    'Open app settings': ['ऐप सेटिंग्स खोलें', 'ایپ کی ترتیبات کھولیں'],
    'Notifications are blocked': ['सूचनाएँ बंद हैं', 'اطلاعات بند ہیں'],
    'Reminders are ready': ['रिमाइंडर तैयार हैं', 'یاد دہانیاں تیار ہیں'],
    'No reminders scheduled': [
      'कोई रिमाइंडर निर्धारित नहीं है',
      'کوئی یاد دہانی مقرر نہیں',
    ],
    'Reminders may arrive late': [
      'रिमाइंडर देर से आ सकते हैं',
      'یاد دہانیاں تاخیر سے آ سکتی ہیں',
    ],
    'Renew reminders': ['रिमाइंडर अपडेट करें', 'یاد دہانیاں تازہ کریں'],
    'Sound': ['ध्वनि', 'آواز'],
    'Silent': ['मौन', 'خاموش'],
    'Notification sound': ['सूचना की ध्वनि', 'اطلاع کی آواز'],
    'Appearance': ['दिखावट', 'ظاہری شکل'],
    'Theme': ['थीम', 'تھیم'],
    'System': ['सिस्टम', 'سسٹم'],
    'Light': ['हल्का', 'روشن'],
    'Dark': ['गहरा', 'تاریک'],
    'Language': ['भाषा', 'زبان'],
    'Advanced calculation settings': [
      'गणना की उन्नत सेटिंग्स',
      'حساب کی جدید ترتیبات',
    ],
    'Calculation method': ['गणना विधि', 'حساب کا طریقہ'],
    'Asr calculation': ['अस्र की गणना', 'عصر کا حساب'],
    'High latitude rule': ['उच्च अक्षांश नियम', 'بلند عرض بلد کا اصول'],
    'Use automatic regional defaults': [
      'क्षेत्र के स्वचालित विकल्प उपयोग करें',
      'علاقائی خودکار ترتیبات استعمال کریں',
    ],
    'Home-screen widget': ['होम स्क्रीन विजेट', 'ہوم اسکرین ویجٹ'],
    'Add widget': ['विजेट जोड़ें', 'ویجٹ شامل کریں'],
    'Next prayer on your home screen': [
      'होम स्क्रीन पर अगली नमाज़',
      'ہوم اسکرین پر اگلی نماز',
    ],
    'Close': ['बंद करें', 'بند کریں'],
    'Try again': ['फिर कोशिश करें', 'دوبارہ کوشش کریں'],
    'Hold steady': ['फ़ोन स्थिर रखें', 'فون ساکن رکھیں'],
    'Checking alignment and compass accuracy': [
      'दिशा और कम्पास की सटीकता जाँची जा रही है',
      'سمت اور کمپاس کی درستگی کی جانچ جاری ہے',
    ],
    'Facing the Qibla': ['क़िबला की ओर हैं', 'قبلہ کی طرف ہیں'],
    'You are aligned with the Kaaba': [
      'आप काबा की दिशा में हैं',
      'آپ کعبہ کی سمت میں ہیں',
    ],
    'Waiting for the compass…': [
      'कम्पास की प्रतीक्षा है…',
      'کمپاس کا انتظار ہے…',
    ],
    'Finding your location…': [
      'आपका स्थान खोजा जा रहा है…',
      'آپ کا مقام تلاش ہو رہا ہے…',
    ],
    'Turn right': ['दाईं ओर मुड़ें', 'دائیں مڑیں'],
    'Turn left': ['बाईं ओर मुड़ें', 'بائیں مڑیں'],
    'To Makkah': ['मक्का की दूरी', 'مکہ کا فاصلہ'],
    'Declination': ['चुंबकीय विचलन', 'مقناطیسی انحراف'],
    'Corrected to true north': [
      'वास्तविक उत्तर के अनुसार',
      'حقیقی شمال کے مطابق',
    ],
    'Jumma / Dhuhr marks the start of Dhuhr. Confirm Friday congregation time with your mosque.': [
      'जुम्मा / ज़ुहर, ज़ुहर की शुरुआत दर्शाता है। जुम्मा की जमात का समय अपनी मस्जिद से पूछें।',
      'جمعہ / ظہر، ظہر کے آغاز کو ظاہر کرتا ہے۔ جمعہ کی جماعت کا وقت اپنی مسجد سے معلوم کریں۔',
    ],
    'Choose a city or enable location to see prayer times.': [
      'नमाज़ के समय देखने के लिए शहर चुनें या स्थान चालू करें।',
      'نماز کے اوقات دیکھنے کے لیے شہر منتخب کریں یا مقام فعال کریں۔',
    ],
    'Times follow this location’s time zone.': [
      'समय इस स्थान के समय क्षेत्र के अनुसार हैं।',
      'اوقات اس مقام کے ٹائم زون کے مطابق ہیں۔',
    ],
    'An estimate is used at this latitude. Confirm times with your mosque.': [
      'इस अक्षांश पर अनुमानित समय है। अपनी मस्जिद से समय की पुष्टि करें।',
      'اس عرض بلد پر اندازاً وقت استعمال ہوا ہے۔ اپنی مسجد سے تصدیق کریں۔',
    ],
    'Regional defaults are selected automatically. Change advanced settings only if needed.': [
      'क्षेत्र के विकल्प स्वचालित रूप से चुने जाते हैं। ज़रूरत होने पर ही उन्नत सेटिंग्स बदलें।',
      'علاقائی ترتیبات خودکار منتخب ہوتی ہیں۔ ضرورت ہو تو جدید ترتیبات بدلیں۔',
    ],
    'City search uses your device’s geocoding service. Suggested cities also work offline.': [
      'शहर की खोज डिवाइस की जियोकोडिंग सेवा उपयोग करती है। सुझाए गए शहर ऑफ़लाइन भी उपलब्ध हैं।',
      'شہر کی تلاش آلے کی جیوکوڈنگ سروس استعمال کرتی ہے۔ تجویز کردہ شہر آف لائن بھی دستیاب ہیں۔',
    ],
    'No city found. Try adding the country name.': [
      'शहर नहीं मिला। देश का नाम भी लिखें।',
      'شہر نہیں ملا۔ ملک کا نام بھی لکھیں۔',
    ],
    'Search unavailable. Choose a suggested city or try again online.': [
      'खोज उपलब्ध नहीं है। सुझाया शहर चुनें या ऑनलाइन फिर कोशिश करें।',
      'تلاش دستیاب نہیں۔ تجویز کردہ شہر منتخب کریں یا آن لائن دوبارہ کوشش کریں۔',
    ],
    'Location is turned off': ['स्थान बंद है', 'مقام بند ہے'],
    'Location permission needed': [
      'स्थान की अनुमति चाहिए',
      'مقام کی اجازت درکار ہے',
    ],
    'Permission blocked': ['अनुमति बंद है', 'اجازت بند ہے'],
    'Could not get a location fix': [
      'स्थान नहीं मिल सका',
      'مقام معلوم نہیں ہو سکا',
    ],
    'Something went wrong': ['कुछ गड़बड़ हुई', 'کچھ غلط ہو گیا'],
    'Open location settings': [
      'स्थान की सेटिंग्स खोलें',
      'مقام کی ترتیبات کھولیں',
    ],
    'Grant permission': ['अनुमति दें', 'اجازت دیں'],
    'Low accuracy — wave the phone in a figure-8': [
      'कम सटीकता — फ़ोन को 8 के आकार में घुमाएँ',
      'کم درستگی — فون کو 8 کی شکل میں گھمائیں',
    ],
    'Fair accuracy — a figure-8 motion will sharpen it': [
      'मध्यम सटीकता — फ़ोन को 8 के आकार में घुमाएँ',
      'درمیانی درستگی — فون کو 8 کی شکل میں گھمائیں',
    ],
    'Readings are unstable. Hold still, away from metal and electronics.': [
      'रीडिंग अस्थिर है। धातु और इलेक्ट्रॉनिक्स से दूर फ़ोन स्थिर रखें।',
      'ریڈنگ غیر مستحکم ہے۔ دھات اور الیکٹرانکس سے دور فون ساکن رکھیں۔',
    ],
    'No compass sensor — use the angle below with a separate compass': [
      'कम्पास सेंसर नहीं है — नीचे का कोण अलग कम्पास के साथ उपयोग करें',
      'کمپاس سینسر نہیں — نیچے دیا زاویہ الگ کمپاس کے ساتھ استعمال کریں',
    ],
    "{prayer} in {minutes} minutes": [
      "{minutes} मिनट में {prayer}",
      "{minutes} منٹ میں {prayer}",
    ],
    "{prayer} time": ["{prayer} का समय", "{prayer} کا وقت"],
    "It is time for {prayer}.": [
      "{prayer} का समय हो गया है।",
      "{prayer} کا وقت ہو گیا ہے۔",
    ],
    "Prepare for the upcoming prayer.": [
      "आने वाली नमाज़ की तैयारी करें।",
      "آنے والی نماز کی تیاری کریں۔",
    ],
    "Dhuhr has begun. Check your mosque for the Jumma congregation time.": [
      "ज़ुहर शुरू हो गया है। जुम्मा की जमात का समय मस्जिद से पूछें।",
      "ظہر شروع ہو گیا ہے۔ جمعہ کی جماعت کا وقت مسجد سے معلوم کریں۔",
    ],
    "Waiting for reliable compass readings": [
      "सटीक कम्पास रीडिंग की प्रतीक्षा है",
      "درست کمپاس ریڈنگ کا انتظار ہے",
    ],
    "Scheduled notifications": ["निर्धारित सूचनाएँ", "مقررہ اطلاعات"],
    "Could not complete this action. Check permissions and try again.": [
      "यह कार्य पूरा नहीं हुआ। अनुमतियाँ जाँचें और फिर कोशिश करें।",
      "یہ کام مکمل نہیں ہوا۔ اجازتیں جانچیں اور دوبارہ کوشش کریں۔",
    ],
    "Reminders renew automatically using your saved location. Open the app after travelling or force-stopping it.": [
      "सहेजे गए स्थान से रिमाइंडर अपने आप अपडेट होते हैं। यात्रा या ऐप को जबरन बंद करने के बाद ऐप खोलें।",
      "محفوظ مقام سے یاد دہانیاں خودکار تازہ ہوتی ہیں۔ سفر یا ایپ کو زبردستی بند کرنے کے بعد ایپ کھولیں۔",
    ],
    "Open the app every few days to renew reminders. Background renewal is available on Android.": [
      "रिमाइंडर अपडेट करने के लिए हर कुछ दिन में ऐप खोलें। बैकग्राउंड अपडेट Android पर उपलब्ध है।",
      "یاد دہانیاں تازہ کرنے کے لیے ہر چند دن بعد ایپ کھولیں۔ پس منظر کی تجدید Android پر دستیاب ہے۔",
    ],
    "Long-press your home screen, choose Widgets, then Qibla Finder.": [
      "होम स्क्रीन को दबाकर रखें, विजेट चुनें, फिर Qibla Finder चुनें।",
      "ہوم اسکرین دبا کر رکھیں، ویجٹس منتخب کریں، پھر Qibla Finder منتخب کریں۔",
    ],
    "Hanafi": ["हनफ़ी", "حنفی"],
    "Standard": ["मानक", "معیاری"],
    "Middle of the night": ["आधी रात", "نصف شب"],
    "One seventh of the night": ["रात का सातवाँ हिस्सा", "رات کا ساتواں حصہ"],
    "Angle based": ["कोण पर आधारित", "زاویے پر مبنی"],
    "Using saved location. Choose a city or retry GPS.": [
      "सहेजा गया स्थान उपयोग हो रहा है। शहर चुनें या GPS फिर आज़माएँ।",
      "محفوظ مقام استعمال ہو رہا ہے۔ شہر منتخب کریں یا GPS دوبارہ آزمائیں۔",
    ],
    "Turn on location services so the Qibla direction can be worked out for where you are.":
        [
          "अपने स्थान की क़िबला दिशा जानने के लिए स्थान सेवाएँ चालू करें।",
          "اپنے مقام کی قبلہ سمت معلوم کرنے کے لیے مقام کی سروس فعال کریں۔",
        ],
    "Location is used to calculate Qibla and prayer times. City names are provided by your device’s geocoding service.": [
      "स्थान से क़िबला और नमाज़ के समय की गणना होती है। शहर के नाम डिवाइस की जियोकोडिंग सेवा देती है।",
      "مقام سے قبلہ اور نماز کے اوقات کا حساب ہوتا ہے۔ شہر کے نام آلے کی جیوکوڈنگ سروس فراہم کرتی ہے۔",
    ],
    "Location permission is permanently denied. Enable it under Permissions in the app settings, then come back.": [
      "स्थान की अनुमति बंद है। ऐप सेटिंग्स में अनुमतियों के अंतर्गत इसे चालू करें, फिर वापस आएँ।",
      "مقام کی اجازت بند ہے۔ ایپ کی ترتیبات میں اجازتیں کھول کر اسے فعال کریں، پھر واپس آئیں۔",
    ],
    "No GPS signal reached the device. Moving near a window or going outside usually fixes this.":
        [
          "GPS सिग्नल नहीं मिला। खिड़की के पास या बाहर जाकर फिर कोशिश करें।",
          "GPS سگنل نہیں ملا۔ کھڑکی کے قریب یا باہر جا کر دوبارہ کوشش کریں۔",
        ],
    "The Qibla direction could not be calculated. Please try again.": [
      "क़िबला दिशा की गणना नहीं हो सकी। फिर कोशिश करें।",
      "قبلہ سمت کا حساب نہیں ہو سکا۔ دوبارہ کوشش کریں۔",
    ],
    "Could not save location. Try again.": [
      "स्थान सहेजा नहीं जा सका। फिर कोशिश करें।",
      "مقام محفوظ نہیں ہو سکا۔ دوبارہ کوشش کریں۔",
    ],
    "Information We Collect": [
      "हम कौन सी जानकारी उपयोग करते हैं",
      "ہم کون سی معلومات استعمال کرتے ہیں",
    ],
    "How We Use Information": ["जानकारी का उपयोग", "معلومات کا استعمال"],
    "Permissions": ["अनुमतियाँ", "اجازتیں"],
    "Contact Us": ["संपर्क करें", "رابطہ کریں"],
    "Policy Changes": ["नीति में बदलाव", "پالیسی میں تبدیلیاں"],
    "Our Commitment to Your Privacy": [
      "आपकी गोपनीयता के प्रति हमारी प्रतिबद्धता",
      "آپ کی رازداری کے لیے ہمارا عزم",
    ],
    "Welcome to Qibla Finder. We are committed to protecting your privacy and ensuring a safe experience for everyone.": [
      "Qibla Finder में आपका स्वागत है। हम आपकी गोपनीयता और सुरक्षित अनुभव के लिए प्रतिबद्ध हैं।",
      "Qibla Finder میں خوش آمدید۔ ہم آپ کی رازداری اور محفوظ تجربے کے لیے پُرعزم ہیں۔",
    ],
    "Qibla and prayer-time calculations run on your device. Your selected or last known location and settings are saved locally. We do not operate a server that collects your location. City search and city-name lookup use your device’s geocoding provider, which may send a search query or coordinates to its service.": [
      "क़िबला और नमाज़ के समय की गणना आपके डिवाइस पर होती है। चुना गया या पिछला स्थान और सेटिंग्स डिवाइस पर सहेजे जाते हैं। हम आपका स्थान एकत्र करने वाला सर्वर नहीं चलाते। शहर की खोज और नाम जानने के लिए डिवाइस की जियोकोडिंग सेवा उपयोग होती है, जो खोज या निर्देशांक अपनी सेवा को भेज सकती है।",
      "قبلہ اور نماز کے اوقات کا حساب آپ کے آلے پر ہوتا ہے۔ منتخب یا آخری معلوم مقام اور ترتیبات آلے پر محفوظ ہوتی ہیں۔ ہم آپ کا مقام جمع کرنے والا سرور نہیں چلاتے۔ شہر کی تلاش اور نام کے لیے آلے کی جیوکوڈنگ سروس استعمال ہوتی ہے، جو تلاش یا نقاط اپنی سروس کو بھیج سکتی ہے۔",
    ],
    "This app contains no analytics or advertising trackers. Saved settings and location support offline calculations and reminder renewal. Platform services handle geocoding and app updates as described here.": [
      "इस ऐप में एनालिटिक्स या विज्ञापन ट्रैकर नहीं हैं। सहेजी गई सेटिंग्स और स्थान ऑफ़लाइन गणना और रिमाइंडर अपडेट करने में उपयोग होते हैं। जियोकोडिंग और ऐप अपडेट प्लेटफ़ॉर्म की सेवाएँ संभालती हैं।",
      "اس ایپ میں اینالیٹکس یا اشتہاری ٹریکر نہیں ہیں۔ محفوظ ترتیبات اور مقام آف لائن حساب اور یاد دہانیوں کی تجدید میں استعمال ہوتے ہیں۔ جیوکوڈنگ اور ایپ اپ ڈیٹس پلیٹ فارم کی سروسز سنبھالتی ہیں۔",
    ],
    "Location permission is optional: choose a city manually or use your device’s current location. The compass uses the device magnetometer. Notification permission enables prayer reminders; precise alarm access is optional. Android renews schedules in the background using the saved location without requesting background location. Google Play handles app-update checks and downloads.": [
      "स्थान की अनुमति वैकल्पिक है: शहर चुनें या डिवाइस का वर्तमान स्थान उपयोग करें। कम्पास डिवाइस के मैग्नेटोमीटर का उपयोग करता है। सूचना की अनुमति से नमाज़ के रिमाइंडर मिलते हैं; सटीक अलार्म की अनुमति वैकल्पिक है। Android सहेजे गए स्थान से बैकग्राउंड में समय अपडेट करता है, बैकग्राउंड स्थान नहीं माँगता। Google Play ऐप अपडेट की जाँच और डाउनलोड संभालता है।",
      "مقام کی اجازت اختیاری ہے: شہر منتخب کریں یا آلے کا موجودہ مقام استعمال کریں۔ کمپاس آلے کا مقناطیسی سینسر استعمال کرتا ہے۔ اطلاع کی اجازت نماز کی یاد دہانیاں فعال کرتی ہے؛ درست الارم کی اجازت اختیاری ہے۔ Android محفوظ مقام سے پس منظر میں اوقات تازہ کرتا ہے اور پس منظر کے مقام کی اجازت نہیں مانگتا۔ Google Play اپ ڈیٹ کی جانچ اور ڈاؤن لوڈ سنبھالتا ہے۔",
    ],
    "If you have any questions or concerns about this privacy policy, please contact us at sadiqueiqbal.si@gmail.com.": [
      "इस गोपनीयता नीति के बारे में प्रश्न हों तो sadiqueiqbal.si@gmail.com पर संपर्क करें।",
      "اس رازداری کی پالیسی کے بارے میں سوالات ہوں تو sadiqueiqbal.si@gmail.com پر رابطہ کریں۔",
    ],
    "We reserve the right to update this privacy policy at any time. Any changes will be reflected on this page.": [
      "इस गोपनीयता नीति को अपडेट किया जा सकता है। बदलाव इस पेज पर दिखेंगे।",
      "اس رازداری کی پالیسی کو اپ ڈیٹ کیا جا سکتا ہے۔ تبدیلیاں اس صفحے پر دکھائی جائیں گی۔",
    ],
    "Now": ["अभी", "ابھی"],
    "Ramadan": ["रमज़ान", "رمضان"],
    "Ramadan {day}": ["रमज़ान {day}", "رمضان {day}"],
    "Showing Ramadan {day}": ["रमज़ान {day} दिख रहा है", "رمضان {day} دکھایا جا رہا ہے"],
    "Iftar": ["इफ़्तार", "افطار"],
    "Adjust times": ["समय समायोजित करें", "اوقات میں تبدیلی"],
    "About": ["ऐप के बारे में", "ایپ کے بارے میں"],
    "Built by {developer}": ["{developer} द्वारा बनाया गया", "{developer} کا بنایا ہوا"],
    "Contact the developer": ["डेवलपर से संपर्क करें", "ڈویلپر سے رابطہ کریں"],
    "Prayer times and the Qibla are calculated, not fetched. If a time does not match your mosque, adjust it above and tell me what you expected.": [
      "नमाज़ के समय और क़िबला गिने जाते हैं, कहीं से लिए नहीं जाते। अगर कोई समय आपकी मस्जिद से मेल न खाए तो ऊपर उसे बदलें और मुझे बताएँ कि आप क्या उम्मीद कर रहे थे।",
      "نماز کے اوقات اور قبلہ شمار کیے جاتے ہیں، کہیں سے لیے نہیں جاتے۔ اگر کوئی وقت آپ کی مسجد سے میل نہ کھائے تو اوپر اسے تبدیل کریں اور مجھے بتائیں کہ آپ کیا توقع کر رہے تھے۔",
    ],
    "Use my location": ["मेरा स्थान उपयोग करें", "میرا مقام استعمال کریں"],
    "The Qibla direction and your prayer times both depend on where you are.": [
      "क़िबला दिशा और आपकी नमाज़ों के समय, दोनों आपके स्थान पर निर्भर करते हैं।",
      "قبلہ سمت اور آپ کی نمازوں کے اوقات، دونوں آپ کے مقام پر منحصر ہیں۔",
    ],
    "Everything is calculated on your device and works offline.": [
      "सब कुछ आपके डिवाइस पर ही गिना जाता है और ऑफ़लाइन काम करता है।",
      "سب کچھ آپ کے آلے پر ہی شمار ہوتا ہے اور آف لائن کام کرتا ہے۔",
    ],
    "No location? Pick your city instead. Nothing is lost either way.": [
      "स्थान नहीं देना चाहते? अपना शहर चुन लें। दोनों तरीक़ों में कुछ कम नहीं होता।",
      "مقام نہیں دینا چاہتے؟ اپنا شہر منتخب کر لیں۔ دونوں طریقوں میں کچھ کم نہیں ہوتا۔",
    ],
    "We do not run a server that collects where you are.": [
      "हम ऐसा कोई सर्वर नहीं चलाते जो आपका स्थान जमा करे।",
      "ہم ایسا کوئی سرور نہیں چلاتے جو آپ کا مقام جمع کرے۔",
    ],
    "On time": ["समय पर", "وقت پر"],
    "Reset adjustments": ["समायोजन हटाएँ", "تبدیلیاں ہٹائیں"],
    "{prayer} one minute earlier": [
      "{prayer} एक मिनट पहले",
      "{prayer} ایک منٹ پہلے",
    ],
    "{prayer} one minute later": [
      "{prayer} एक मिनट बाद",
      "{prayer} ایک منٹ بعد",
    ],
    "If your mosque publishes times a few minutes apart from these, shift each prayer to match. Reminders follow the adjusted time.": [
      "अगर आपकी मस्जिद इनसे कुछ मिनट अलग समय देती है, तो हर नमाज़ को उसी अनुसार बदलें। रिमाइंडर बदले हुए समय पर आएँगे।",
      "اگر آپ کی مسجد ان سے چند منٹ مختلف اوقات دیتی ہے تو ہر نماز کو اسی کے مطابق تبدیل کریں۔ یاد دہانیاں تبدیل شدہ وقت پر آئیں گی۔",
    ],
    "Suhoor and iftar reminders": [
      "सहरी और इफ़्तार के रिमाइंडर",
      "سحری اور افطار کی یاد دہانیاں",
    ],
    "Warn me before suhoor ends": [
      "सहरी ख़त्म होने से पहले बताएँ",
      "سحری ختم ہونے سے پہلے بتائیں",
    ],
    "At Fajr only": ["सिर्फ़ फ़ज्र पर", "صرف فجر پر"],
    "45 minutes before": ["45 मिनट पहले", "45 منٹ پہلے"],
    "60 minutes before": ["60 मिनट पहले", "60 منٹ پہلے"],
    "Suhoor ends in {minutes} minutes": [
      "{minutes} मिनट में सहरी ख़त्म",
      "{minutes} منٹ میں سحری ختم",
    ],
    "Fajr is close. Finish suhoor before it begins.": [
      "फ़ज्र क़रीब है। उससे पहले सहरी पूरी कर लें।",
      "فجر قریب ہے۔ اس سے پہلے سحری مکمل کر لیں۔",
    ],
    "Maghrib has begun. You may break your fast.": [
      "मग़रिब हो गई है। अब रोज़ा खोल सकते हैं।",
      "مغرب ہو گئی ہے۔ اب روزہ کھول سکتے ہیں۔",
    ],
    "These are scheduled during Ramadan only, on top of your prayer reminders.": [
      "ये सिर्फ़ रमज़ान में लगते हैं, नमाज़ के रिमाइंडर के अलावा।",
      "یہ صرف رمضان میں مقرر ہوتی ہیں، نماز کی یاد دہانیوں کے علاوہ۔",
    ],
    "Suhoor ends": ["सहरी समाप्त", "سحری ختم"],
    "Show suhoor and iftar": ["सहरी और इफ़्तार दिखाएँ", "سحری اور افطار دکھائیں"],
    "A day earlier": ["एक दिन पहले", "ایک دن پہلے"],
    "A day later": ["एक दिन बाद", "ایک دن بعد"],
    "Off": ["बंद", "بند"],
    "Suhoor and iftar appear during Ramadan only. The Hijri date is calculated, so if your mosque started a day earlier or later, shift it to match.": [
      "सहरी और इफ़्तार सिर्फ़ रमज़ान में दिखते हैं। हिजरी तारीख़ गणना से निकाली जाती है, इसलिए अगर आपकी मस्जिद ने एक दिन पहले या बाद शुरू किया हो तो उसी अनुसार बदलें।",
      "سحری اور افطار صرف رمضان میں دکھائی دیتے ہیں۔ ہجری تاریخ حساب سے نکالی جاتی ہے، اس لیے اگر آپ کی مسجد نے ایک دن پہلے یا بعد شروع کیا ہو تو اسی کے مطابق تبدیل کریں۔",
    ],
    "Refresh": ["अपडेट करें", "تازہ کریں"],
    "Next": ["अगली", "اگلی"],
    "Not a prayer": ["नमाज़ नहीं", "نماز نہیں"],
    "Which prayers": ["कौन सी नमाज़ें", "کون سی نمازیں"],
    "Reminder status": ["रिमाइंडर की स्थिति", "یاد دہانی کی حالت"],
    "Check that reminders are permitted and scheduled on this device.": [
      "जाँचें कि इस डिवाइस पर रिमाइंडर की अनुमति है और वे निर्धारित हैं।",
      "جانچیں کہ اس آلے پر یاد دہانیوں کی اجازت ہے اور وہ مقرر ہیں۔",
    ],
    "Weekly timetable": ["साप्ताहिक समय-सारणी", "ہفتہ وار نظام الاوقات"],
    "Day": ["दिन", "دن"],
    "Last known location": ["पिछला ज्ञात स्थान", "آخری معلوم مقام"],
    "Locating…": ["स्थान खोजा जा रहा है…", "مقام تلاش کیا جا رہا ہے…"],
    "Qibla compass": ["क़िबला कम्पास", "قبلہ کمپاس"],
    "Location unavailable": ["स्थान उपलब्ध नहीं", "مقام دستیاب نہیں"],
    "Qibla bearing {degrees} degrees from true north": [
      "असली उत्तर से क़िबला दिशा {degrees} डिग्री",
      "حقیقی شمال سے قبلہ سمت {degrees} ڈگری",
    ],
    "Your test reminder is working.": [
      "आपका टेस्ट रिमाइंडर काम कर रहा है।",
      "آپ کی ٹیسٹ یاد دہانی کام کر رہی ہے۔",
    ],
    "{madhab} Asr": ["{madhab} अस्र", "{madhab} عصر"],
    "Last updated: 12 September 2026": [
      "आखिरी अपडेट: 12 सितंबर 2026",
      "آخری تازہ کاری: 12 ستمبر 2026",
    ],
  };
}
