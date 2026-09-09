import json
import os

arb_dir = '/home/limbo/Desktop/marcoStock/lib/src/localization/arb'
en_file = os.path.join(arb_dir, 'app_en.arb')
ar_file = os.path.join(arb_dir, 'app_ar.arb')

with open(en_file, 'r', encoding='utf-8') as f:
    en_data = json.load(f)

with open(ar_file, 'r', encoding='utf-8') as f:
    ar_data = json.load(f)

additions_en = {
    "stockTransfers": "Stock Transfers",
    "returns": "Returns",
    "archiveDocs": "Archive & Docs",
    "administration": "ADMINISTRATION",
    "settings": "Settings",
    "logout": "Logout",
    "savedSuccessfully": "Saved Successfully",
    "companyProfile": "Company Profile",
    "saveProfile": "Save Profile",
    "settingsSystem": "Settings & System",
    "company": "Company",
    "manageCompanyDetails": "Manage company details, tax ID, and logo",
    "preferences": "Preferences",
    "theme": "Theme",
    "system": "System",
    "light": "Light",
    "dark": "Dark",
    "language": "Language",
    "systemMaintenance": "System Maintenance",
    "forceSync": "Force Sync",
    "pushPendingChanges": "Push pending changes to cloud",
    "syncing": "Syncing...",
    "syncComplete": "Sync Complete",
    "checkForUpdates": "Check for Updates",
    "connectsToGithub": "Connects to GitHub Releases",
    "updateAvailable": "Update Available",
    "newVersionAvailable": "A new version is available on GitHub.",
    "later": "Later",
    "download": "Download",
    "appUpToDate": "App is up to date.",
    "backupDatabase": "Backup Database",
    "selectBackupLocation": "Select a location to save a copy of the database",
    "backupSavedTo": "Backup saved to: ",
    "backupCancelled": "Backup cancelled",
    "errorSaving": "Error saving: ",
    "requiredField": "Required",
    "unitsPerBox": "Units per Box",
    "errorLoadingProducts": "Error loading products: ",
    "unit": "Unit",
    "box": "Box",
    "cash": "CASH",
    "check": "CHECK",
    "credit": "CREDIT",
    "checkImage": "Check Image",
    "creditMonthlySalary": "Credit Monthly Salary",
    "creditBonus": "Credit Bonus",
    "transactionHistory": "Transaction History",
    "checks": "Checks",
    "errorStr": "Error: ",
    "checkImageAvailable": "Check Image Available",
    "errorSavingPayments": "Error saving payments: ",
    "save": "Save"
}

additions_ar = {
    "stockTransfers": "تحويلات المخزون",
    "returns": "المرتجعات",
    "archiveDocs": "الأرشيف والمستندات",
    "administration": "الإدارة",
    "settings": "الإعدادات",
    "logout": "تسجيل خروج",
    "savedSuccessfully": "تم الحفظ بنجاح",
    "companyProfile": "ملف الشركة",
    "saveProfile": "حفظ الملف",
    "settingsSystem": "الإعدادات والنظام",
    "company": "الشركة",
    "manageCompanyDetails": "إدارة تفاصيل الشركة، الرقم الضريبي، والشعار",
    "preferences": "التفضيلات",
    "theme": "المظهر",
    "system": "النظام",
    "light": "فاتح",
    "dark": "داكن",
    "language": "اللغة",
    "systemMaintenance": "صيانة النظام",
    "forceSync": "مزامنة قسرية",
    "pushPendingChanges": "دفع التغييرات المعلقة إلى السحابة",
    "syncing": "جاري المزامنة...",
    "syncComplete": "اكتملت المزامنة",
    "checkForUpdates": "التحقق من التحديثات",
    "connectsToGithub": "يتصل بإصدارات GitHub",
    "updateAvailable": "تحديث متاح",
    "newVersionAvailable": "يتوفر إصدار جديد على GitHub.",
    "later": "لاحقاً",
    "download": "تنزيل",
    "appUpToDate": "التطبيق مُحدث.",
    "backupDatabase": "نسخ احتياطي لقاعدة البيانات",
    "selectBackupLocation": "حدد موقعاً لحفظ نسخة من قاعدة البيانات",
    "backupSavedTo": "تم حفظ النسخة الاحتياطية في: ",
    "backupCancelled": "تم إلغاء النسخ الاحتياطي",
    "errorSaving": "خطأ في الحفظ: ",
    "requiredField": "مطلوب",
    "unitsPerBox": "الوحدات لكل صندوق",
    "errorLoadingProducts": "خطأ في تحميل المنتجات: ",
    "unit": "وحدة",
    "box": "صندوق",
    "cash": "نقدي",
    "check": "شيك",
    "credit": "آجل",
    "checkImage": "صورة الشيك",
    "creditMonthlySalary": "إيداع راتب شهري",
    "creditBonus": "إيداع مكافأة",
    "transactionHistory": "سجل المعاملات",
    "checks": "شيكات",
    "errorStr": "خطأ: ",
    "checkImageAvailable": "صورة الشيك متاحة",
    "errorSavingPayments": "خطأ في حفظ المدفوعات: ",
    "save": "حفظ"
}

en_data.update(additions_en)
ar_data.update(additions_ar)

with open(en_file, 'w', encoding='utf-8') as f:
    json.dump(en_data, f, ensure_ascii=False, indent=2)

with open(ar_file, 'w', encoding='utf-8') as f:
    json.dump(ar_data, f, ensure_ascii=False, indent=2)

print("Updated ARB files.")
