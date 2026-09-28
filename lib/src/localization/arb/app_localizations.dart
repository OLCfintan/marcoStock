import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'arb/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Marko Group'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliers;

  /// No description provided for @salesPos.
  ///
  /// In en, this message translates to:
  /// **'Sales (POS)'**
  String get salesPos;

  /// No description provided for @purchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get purchases;

  /// No description provided for @employeesHr.
  ///
  /// In en, this message translates to:
  /// **'Employees (HR)'**
  String get employeesHr;

  /// No description provided for @stockTransfers.
  ///
  /// In en, this message translates to:
  /// **'Stock Transfers'**
  String get stockTransfers;

  /// No description provided for @returns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get returns;

  /// No description provided for @archiveDocs.
  ///
  /// In en, this message translates to:
  /// **'Archive & Docs'**
  String get archiveDocs;

  /// No description provided for @administration.
  ///
  /// In en, this message translates to:
  /// **'ADMINISTRATION'**
  String get administration;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved Successfully'**
  String get savedSuccessfully;

  /// No description provided for @companyProfile.
  ///
  /// In en, this message translates to:
  /// **'Company Profile'**
  String get companyProfile;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @settingsSystem.
  ///
  /// In en, this message translates to:
  /// **'Settings & System'**
  String get settingsSystem;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @manageCompanyDetails.
  ///
  /// In en, this message translates to:
  /// **'Manage company details, tax ID, and logo'**
  String get manageCompanyDetails;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemMaintenance.
  ///
  /// In en, this message translates to:
  /// **'System Maintenance'**
  String get systemMaintenance;

  /// No description provided for @forceSync.
  ///
  /// In en, this message translates to:
  /// **'Force Sync'**
  String get forceSync;

  /// No description provided for @pushPendingChanges.
  ///
  /// In en, this message translates to:
  /// **'Push pending changes to cloud'**
  String get pushPendingChanges;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync Complete'**
  String get syncComplete;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkForUpdates;

  /// No description provided for @connectsToGithub.
  ///
  /// In en, this message translates to:
  /// **'Connects to GitHub Releases'**
  String get connectsToGithub;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version is available on GitHub.'**
  String get newVersionAvailable;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @appUpToDate.
  ///
  /// In en, this message translates to:
  /// **'App is up to date.'**
  String get appUpToDate;

  /// No description provided for @backupDatabase.
  ///
  /// In en, this message translates to:
  /// **'Backup Database'**
  String get backupDatabase;

  /// No description provided for @selectBackupLocation.
  ///
  /// In en, this message translates to:
  /// **'Select a location to save a copy of the database'**
  String get selectBackupLocation;

  /// No description provided for @backupSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Backup saved to: '**
  String get backupSavedTo;

  /// No description provided for @backupCancelled.
  ///
  /// In en, this message translates to:
  /// **'Backup cancelled'**
  String get backupCancelled;

  /// No description provided for @errorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving: '**
  String get errorSaving;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @unitsPerBox.
  ///
  /// In en, this message translates to:
  /// **'Units per Box'**
  String get unitsPerBox;

  /// No description provided for @errorLoadingProducts.
  ///
  /// In en, this message translates to:
  /// **'Error loading products: '**
  String get errorLoadingProducts;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @box.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get box;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'CASH'**
  String get cash;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'CHECK'**
  String get check;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'CREDIT'**
  String get credit;

  /// No description provided for @checkImage.
  ///
  /// In en, this message translates to:
  /// **'Check Image'**
  String get checkImage;

  /// No description provided for @creditMonthlySalary.
  ///
  /// In en, this message translates to:
  /// **'Credit Monthly Salary'**
  String get creditMonthlySalary;

  /// No description provided for @creditBonus.
  ///
  /// In en, this message translates to:
  /// **'Credit Bonus'**
  String get creditBonus;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @checks.
  ///
  /// In en, this message translates to:
  /// **'Checks'**
  String get checks;

  /// No description provided for @errorStr.
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get errorStr;

  /// No description provided for @checkImageAvailable.
  ///
  /// In en, this message translates to:
  /// **'Check Image Available'**
  String get checkImageAvailable;

  /// No description provided for @errorSavingPayments.
  ///
  /// In en, this message translates to:
  /// **'Error saving payments: '**
  String get errorSavingPayments;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @pendingChecks.
  ///
  /// In en, this message translates to:
  /// **'Pending Checks'**
  String get pendingChecks;

  /// No description provided for @boxes.
  ///
  /// In en, this message translates to:
  /// **'Boxes'**
  String get boxes;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found: '**
  String get productNotFound;

  /// No description provided for @pleaseSelectClientAndProducts.
  ///
  /// In en, this message translates to:
  /// **'Please select a client and add products.'**
  String get pleaseSelectClientAndProducts;

  /// No description provided for @saleCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Sale completed successfully!'**
  String get saleCompletedSuccessfully;

  /// No description provided for @newSalePos.
  ///
  /// In en, this message translates to:
  /// **'New Sale (POS)'**
  String get newSalePos;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @bon.
  ///
  /// In en, this message translates to:
  /// **'BON'**
  String get bon;

  /// No description provided for @ticket.
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get ticket;

  /// No description provided for @addPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Add Payment Method'**
  String get addPaymentMethod;

  /// No description provided for @adjustQuantity.
  ///
  /// In en, this message translates to:
  /// **'Adjust Quantity - '**
  String get adjustQuantity;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get confirmPayment;

  /// No description provided for @productExists.
  ///
  /// In en, this message translates to:
  /// **'A Product with this name already exists.'**
  String get productExists;

  /// No description provided for @fillRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields correctly.'**
  String get fillRequiredFields;

  /// No description provided for @selectValidProductForLinked.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid product for all linked items.'**
  String get selectValidProductForLinked;

  /// No description provided for @addNewProduct.
  ///
  /// In en, this message translates to:
  /// **'Add New Product'**
  String get addNewProduct;

  /// No description provided for @addConsumablesDesc.
  ///
  /// In en, this message translates to:
  /// **'Add consumables required to make 1 unit of this product.'**
  String get addConsumablesDesc;

  /// No description provided for @addConsumable.
  ///
  /// In en, this message translates to:
  /// **'Add Consumable'**
  String get addConsumable;

  /// No description provided for @clientExists.
  ///
  /// In en, this message translates to:
  /// **'A Client with this name already exists.'**
  String get clientExists;

  /// No description provided for @addNewClient.
  ///
  /// In en, this message translates to:
  /// **'Add New Client'**
  String get addNewClient;

  /// No description provided for @supplierExists.
  ///
  /// In en, this message translates to:
  /// **'A Supplier with this name already exists.'**
  String get supplierExists;

  /// No description provided for @addNewSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add New Supplier'**
  String get addNewSupplier;

  /// No description provided for @employeeExists.
  ///
  /// In en, this message translates to:
  /// **'A Employee with this name already exists.'**
  String get employeeExists;

  /// No description provided for @addNewEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add New Employee'**
  String get addNewEmployee;

  /// No description provided for @payrollAction.
  ///
  /// In en, this message translates to:
  /// **'Payroll Action: '**
  String get payrollAction;

  /// No description provided for @issueAdvance.
  ///
  /// In en, this message translates to:
  /// **'Issue Advance (Deduct)'**
  String get issueAdvance;

  /// No description provided for @issueFinalPayment.
  ///
  /// In en, this message translates to:
  /// **'Issue Final Payment (Deduct)'**
  String get issueFinalPayment;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @profileOf.
  ///
  /// In en, this message translates to:
  /// **' Profile'**
  String get profileOf;

  /// No description provided for @noTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No transactions found.'**
  String get noTransactionsFound;

  /// No description provided for @totalDue.
  ///
  /// In en, this message translates to:
  /// **'Total Due:'**
  String get totalDue;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid:'**
  String get totalPaid;

  /// No description provided for @remainingBalance.
  ///
  /// In en, this message translates to:
  /// **'Remaining Balance:'**
  String get remainingBalance;

  /// No description provided for @totalOwed.
  ///
  /// In en, this message translates to:
  /// **'Total Owed:'**
  String get totalOwed;

  /// No description provided for @confirmSale.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM SALE'**
  String get confirmSale;

  /// No description provided for @confirmPurchase.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM PURCHASE'**
  String get confirmPurchase;

  /// No description provided for @each.
  ///
  /// In en, this message translates to:
  /// **'each'**
  String get each;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost:'**
  String get cost;

  /// No description provided for @tableName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get tableName;

  /// No description provided for @tableCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get tableCategory;

  /// No description provided for @tableBaseUnit.
  ///
  /// In en, this message translates to:
  /// **'Base Unit'**
  String get tableBaseUnit;

  /// No description provided for @tablePurchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price'**
  String get tablePurchasePrice;

  /// No description provided for @tableSellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get tableSellingPrice;

  /// No description provided for @tableTier2.
  ///
  /// In en, this message translates to:
  /// **'Tier 2'**
  String get tableTier2;

  /// No description provided for @tableTier3.
  ///
  /// In en, this message translates to:
  /// **'Tier 3'**
  String get tableTier3;

  /// No description provided for @tableMinStock.
  ///
  /// In en, this message translates to:
  /// **'Min Stock'**
  String get tableMinStock;

  /// No description provided for @tableActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get tableActions;

  /// No description provided for @tableContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get tableContact;

  /// No description provided for @tableBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get tableBalance;

  /// No description provided for @tablePosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get tablePosition;

  /// No description provided for @tableRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get tableRole;

  /// No description provided for @pdfDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get pdfDate;

  /// No description provided for @pdfStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get pdfStatus;

  /// No description provided for @pdfBillTo.
  ///
  /// In en, this message translates to:
  /// **'Bill To:'**
  String get pdfBillTo;

  /// No description provided for @pdfItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get pdfItem;

  /// No description provided for @pdfQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get pdfQty;

  /// No description provided for @pdfTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get pdfTotal;

  /// No description provided for @pdfPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get pdfPrice;

  /// No description provided for @pdfSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get pdfSubtotal;

  /// No description provided for @pdfTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get pdfTax;

  /// No description provided for @pdfGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get pdfGrandTotal;

  /// No description provided for @pdfThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your business!'**
  String get pdfThankYou;

  /// No description provided for @pdfPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get pdfPurchase;

  /// No description provided for @pdfSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier:'**
  String get pdfSupplier;

  /// No description provided for @paymentExceedsTotal.
  ///
  /// In en, this message translates to:
  /// **'Payment amount cannot exceed the total.'**
  String get paymentExceedsTotal;

  /// No description provided for @walkInClient.
  ///
  /// In en, this message translates to:
  /// **'Client Passager'**
  String get walkInClient;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @confirmReturn.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM RETURN'**
  String get confirmReturn;

  /// No description provided for @processReturn.
  ///
  /// In en, this message translates to:
  /// **'Process Return'**
  String get processReturn;

  /// No description provided for @garbage.
  ///
  /// In en, this message translates to:
  /// **'Garbage / Deleted'**
  String get garbage;

  /// No description provided for @recordPurchase.
  ///
  /// In en, this message translates to:
  /// **'RECORD PURCHASE'**
  String get recordPurchase;

  /// No description provided for @recordInboundPurchase.
  ///
  /// In en, this message translates to:
  /// **'Record Inbound Purchase (ACH)'**
  String get recordInboundPurchase;

  /// No description provided for @returnCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Return completed successfully!'**
  String get returnCompletedSuccessfully;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// No description provided for @pdfPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get pdfPaid;

  /// No description provided for @pdfBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get pdfBalance;

  /// No description provided for @pdfDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get pdfDiscount;

  /// No description provided for @documentType.
  ///
  /// In en, this message translates to:
  /// **'Document Type'**
  String get documentType;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @selectClient.
  ///
  /// In en, this message translates to:
  /// **'Select Client'**
  String get selectClient;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @unitCost.
  ///
  /// In en, this message translates to:
  /// **'Unit Cost'**
  String get unitCost;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @productsTab.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTab;

  /// No description provided for @cartTab.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cartTab;

  /// No description provided for @returnCartTab.
  ///
  /// In en, this message translates to:
  /// **'Return Cart'**
  String get returnCartTab;

  /// No description provided for @purchaseCartTab.
  ///
  /// In en, this message translates to:
  /// **'Purchase Cart'**
  String get purchaseCartTab;

  /// No description provided for @convertToInvoice.
  ///
  /// In en, this message translates to:
  /// **'Convert to Invoice'**
  String get convertToInvoice;

  /// No description provided for @convertBonToInvoice.
  ///
  /// In en, this message translates to:
  /// **'Convert this Bon to an Invoice?'**
  String get convertBonToInvoice;

  /// No description provided for @convertedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Bon converted to Invoice successfully!'**
  String get convertedSuccessfully;

  /// No description provided for @searchSupplier.
  ///
  /// In en, this message translates to:
  /// **'Search Supplier...'**
  String get searchSupplier;

  /// No description provided for @pdfBonTo.
  ///
  /// In en, this message translates to:
  /// **'BON To:'**
  String get pdfBonTo;

  /// No description provided for @pdfTotalDebt.
  ///
  /// In en, this message translates to:
  /// **'Total Debt'**
  String get pdfTotalDebt;

  /// No description provided for @pdfRemainingInInvoice.
  ///
  /// In en, this message translates to:
  /// **'Remaining in this Invoice'**
  String get pdfRemainingInInvoice;

  /// No description provided for @pdfRemainingInBon.
  ///
  /// In en, this message translates to:
  /// **'Remaining in this BON'**
  String get pdfRemainingInBon;

  /// No description provided for @deleteStr.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteStr;

  /// No description provided for @createConsumables.
  ///
  /// In en, this message translates to:
  /// **'Create Consumables'**
  String get createConsumables;

  /// No description provided for @addFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Add Family Member'**
  String get addFamilyMember;

  /// No description provided for @ledgerPayments.
  ///
  /// In en, this message translates to:
  /// **'Ledger / Payments'**
  String get ledgerPayments;

  /// No description provided for @printDocument.
  ///
  /// In en, this message translates to:
  /// **'Print Document'**
  String get printDocument;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @viewPaymentsChecks.
  ///
  /// In en, this message translates to:
  /// **'View Payments & Checks'**
  String get viewPaymentsChecks;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productNameLabel;

  /// No description provided for @referenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference (optional)'**
  String get referenceLabel;

  /// No description provided for @purchasePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price'**
  String get purchasePriceLabel;

  /// No description provided for @sellingPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get sellingPriceLabel;

  /// No description provided for @tier2PriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Tier 2 Price (optional)'**
  String get tier2PriceLabel;

  /// No description provided for @tier3PriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Tier 3 Price (optional)'**
  String get tier3PriceLabel;

  /// No description provided for @packagingLabel.
  ///
  /// In en, this message translates to:
  /// **'Packaging (e.g., Box, Unit)'**
  String get packagingLabel;

  /// No description provided for @unitTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit Type'**
  String get unitTypeLabel;

  /// No description provided for @unitSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit Size'**
  String get unitSizeLabel;

  /// No description provided for @unitsPerBoxLabel.
  ///
  /// In en, this message translates to:
  /// **'Units Per Box'**
  String get unitsPerBoxLabel;

  /// No description provided for @baseMinStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Base Min Stock'**
  String get baseMinStockLabel;

  /// No description provided for @magazinMinStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Magazin Min Stock'**
  String get magazinMinStockLabel;

  /// No description provided for @arabicTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Arabic Tag'**
  String get arabicTagLabel;

  /// No description provided for @frenchTagLabel.
  ///
  /// In en, this message translates to:
  /// **'French Tag'**
  String get frenchTagLabel;

  /// No description provided for @spanishTagLabel.
  ///
  /// In en, this message translates to:
  /// **'Spanish Tag'**
  String get spanishTagLabel;

  /// No description provided for @saveStr.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveStr;

  /// No description provided for @cancelStr.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelStr;

  /// No description provided for @stockLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock Levels'**
  String get stockLevelLabel;

  /// No description provided for @baseLabel.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get baseLabel;

  /// No description provided for @magazinLabel.
  ///
  /// In en, this message translates to:
  /// **'Magazin'**
  String get magazinLabel;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @stockTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stockTitle;

  /// No description provided for @salesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesTitle;

  /// No description provided for @totalSalesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get totalSalesLabel;

  /// No description provided for @totalPurchasesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Purchases'**
  String get totalPurchasesLabel;

  /// No description provided for @cashInRegisterLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash in Register'**
  String get cashInRegisterLabel;

  /// No description provided for @recentTransactionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactionsLabel;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @salesOverTime.
  ///
  /// In en, this message translates to:
  /// **'Sales Over Time'**
  String get salesOverTime;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @topSellingProducts.
  ///
  /// In en, this message translates to:
  /// **'Top-Selling Products'**
  String get topSellingProducts;

  /// No description provided for @employeePerformance.
  ///
  /// In en, this message translates to:
  /// **'Employee Performance'**
  String get employeePerformance;

  /// No description provided for @topClientsDebt.
  ///
  /// In en, this message translates to:
  /// **'Top Clients (Debt)'**
  String get topClientsDebt;

  /// No description provided for @topSuppliersDebt.
  ///
  /// In en, this message translates to:
  /// **'Top Suppliers (Debt)'**
  String get topSuppliersDebt;

  /// No description provided for @topClientsRevenue.
  ///
  /// In en, this message translates to:
  /// **'Top Clients (Cash/Revenue)'**
  String get topClientsRevenue;

  /// No description provided for @topSuppliersPaid.
  ///
  /// In en, this message translates to:
  /// **'Top Suppliers (Cash Paid)'**
  String get topSuppliersPaid;

  /// No description provided for @lowStockAlerts.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alerts'**
  String get lowStockAlerts;

  /// No description provided for @todaysSales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales'**
  String get todaysSales;

  /// No description provided for @todaysSalesDetails.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales Details'**
  String get todaysSalesDetails;

  /// No description provided for @totalCredit.
  ///
  /// In en, this message translates to:
  /// **'Total Credit'**
  String get totalCredit;

  /// No description provided for @totalCreditDetails.
  ///
  /// In en, this message translates to:
  /// **'Total Credit Details'**
  String get totalCreditDetails;

  /// No description provided for @todaysCredit.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Credit'**
  String get todaysCredit;

  /// No description provided for @todaysCreditDetails.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Credit Details'**
  String get todaysCreditDetails;

  /// No description provided for @stockLevelsGood.
  ///
  /// In en, this message translates to:
  /// **'Stock levels are good!'**
  String get stockLevelsGood;

  /// No description provided for @currentStockMin.
  ///
  /// In en, this message translates to:
  /// **'Current Stock: {current} (Min: {min})'**
  String currentStockMin(Object current, Object min);

  /// No description provided for @restock.
  ///
  /// In en, this message translates to:
  /// **'RESTOCK'**
  String get restock;

  /// No description provided for @noSalesData.
  ///
  /// In en, this message translates to:
  /// **'No sales data available'**
  String get noSalesData;

  /// No description provided for @qtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty: {qty}'**
  String qtyLabel(Object qty);

  /// No description provided for @noPerformanceData.
  ///
  /// In en, this message translates to:
  /// **'No performance data available'**
  String get noPerformanceData;

  /// No description provided for @noClientData.
  ///
  /// In en, this message translates to:
  /// **'No client data available'**
  String get noClientData;

  /// No description provided for @noSupplierData.
  ///
  /// In en, this message translates to:
  /// **'No supplier data available'**
  String get noSupplierData;

  /// No description provided for @noPaymentData.
  ///
  /// In en, this message translates to:
  /// **'No payment data available'**
  String get noPaymentData;

  /// No description provided for @baseWarehouseStockValue.
  ///
  /// In en, this message translates to:
  /// **'Base Warehouse Stock Value'**
  String get baseWarehouseStockValue;

  /// No description provided for @magazinStockValue.
  ///
  /// In en, this message translates to:
  /// **'Magazin Stock Value'**
  String get magazinStockValue;

  /// No description provided for @noStockData.
  ///
  /// In en, this message translates to:
  /// **'No stock data'**
  String get noStockData;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get failedToLoad;

  /// No description provided for @bonDeLivraison.
  ///
  /// In en, this message translates to:
  /// **'Delivery Note'**
  String get bonDeLivraison;

  /// No description provided for @bonDeCommande.
  ///
  /// In en, this message translates to:
  /// **'Order Note'**
  String get bonDeCommande;

  /// No description provided for @pdfBonDeLivraison.
  ///
  /// In en, this message translates to:
  /// **'Delivery Note'**
  String get pdfBonDeLivraison;

  /// No description provided for @pdfBonDeCommande.
  ///
  /// In en, this message translates to:
  /// **'Order Note'**
  String get pdfBonDeCommande;

  /// No description provided for @pdfFacture.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get pdfFacture;

  /// No description provided for @invoiceCounter.
  ///
  /// In en, this message translates to:
  /// **'Invoice Counter'**
  String get invoiceCounter;

  /// No description provided for @invoiceCounterPrefix.
  ///
  /// In en, this message translates to:
  /// **'Counter Prefix (e.g. MG)'**
  String get invoiceCounterPrefix;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice Number'**
  String get invoiceNumber;

  /// No description provided for @invoiceDate.
  ///
  /// In en, this message translates to:
  /// **'Invoice Date'**
  String get invoiceDate;

  /// No description provided for @commandeCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order note created successfully!'**
  String get commandeCreatedSuccessfully;

  /// No description provided for @changeMyPin.
  ///
  /// In en, this message translates to:
  /// **'Change My PIN'**
  String get changeMyPin;

  /// No description provided for @newPinCode.
  ///
  /// In en, this message translates to:
  /// **'New PIN Code'**
  String get newPinCode;

  /// No description provided for @pinUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PIN updated successfully'**
  String get pinUpdatedSuccessfully;

  /// No description provided for @adminSecurity.
  ///
  /// In en, this message translates to:
  /// **'Admin Security'**
  String get adminSecurity;

  /// No description provided for @changeAdminPin.
  ///
  /// In en, this message translates to:
  /// **'Change Admin PIN'**
  String get changeAdminPin;

  /// No description provided for @updatePersonalPin.
  ///
  /// In en, this message translates to:
  /// **'Update your personal login PIN code'**
  String get updatePersonalPin;

  /// No description provided for @recycleBin.
  ///
  /// In en, this message translates to:
  /// **'Recycle Bin'**
  String get recycleBin;

  /// No description provided for @exportImportSystem.
  ///
  /// In en, this message translates to:
  /// **'Export & Import System'**
  String get exportImportSystem;

  /// No description provided for @exportMarkoSave.
  ///
  /// In en, this message translates to:
  /// **'Export Marko-Save'**
  String get exportMarkoSave;

  /// No description provided for @exportFullSystem.
  ///
  /// In en, this message translates to:
  /// **'Export full system structure (DB, PDFs, Images, TXTs) to a folder.'**
  String get exportFullSystem;

  /// No description provided for @startingExport.
  ///
  /// In en, this message translates to:
  /// **'Starting Export... This may take a moment to generate all PDFs.'**
  String get startingExport;

  /// No description provided for @exportCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Export completed successfully!'**
  String get exportCompletedSuccessfully;

  /// No description provided for @importMarkoSave.
  ///
  /// In en, this message translates to:
  /// **'Import Marko-Save'**
  String get importMarkoSave;

  /// No description provided for @restoreDatabaseOrBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore database (select .sqlite) or full backup (select .zip).'**
  String get restoreDatabaseOrBackup;

  /// No description provided for @confirmImport.
  ///
  /// In en, this message translates to:
  /// **'Confirm Import'**
  String get confirmImport;

  /// No description provided for @overwriteDatabaseConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will OVERWRITE your current database with the Marko-Save backup. Are you sure?'**
  String get overwriteDatabaseConfirm;

  /// No description provided for @yesOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Yes, Overwrite'**
  String get yesOverwrite;

  /// No description provided for @importCompletedRestart.
  ///
  /// In en, this message translates to:
  /// **'Import completed! Please restart the app.'**
  String get importCompletedRestart;

  /// No description provided for @importMasterData.
  ///
  /// In en, this message translates to:
  /// **'Import Master Data (TXT/CSV/PDF)'**
  String get importMasterData;

  /// No description provided for @importStrictFormat.
  ///
  /// In en, this message translates to:
  /// **'Import strict format Clients, Suppliers, or Products data'**
  String get importStrictFormat;

  /// No description provided for @viewImportFormat.
  ///
  /// In en, this message translates to:
  /// **'View Import Format Instructions'**
  String get viewImportFormat;

  /// No description provided for @importFormatPrototype.
  ///
  /// In en, this message translates to:
  /// **'Import Format Prototype'**
  String get importFormatPrototype;

  /// No description provided for @importDataFormatDesc.
  ///
  /// In en, this message translates to:
  /// **'Data should be plain text blocks separated by \"---\". Field names are case-insensitive. Spaces and underscores are ignored in keys.'**
  String get importDataFormatDesc;

  /// No description provided for @productTemplate.
  ///
  /// In en, this message translates to:
  /// **'Product Template:'**
  String get productTemplate;

  /// No description provided for @clientTemplate.
  ///
  /// In en, this message translates to:
  /// **'Client Template:'**
  String get clientTemplate;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @wipeDatabase.
  ///
  /// In en, this message translates to:
  /// **'Wipe Database (Clear All Data)'**
  String get wipeDatabase;

  /// No description provided for @deletesAllData.
  ///
  /// In en, this message translates to:
  /// **'Deletes all products, clients, stock, and history.'**
  String get deletesAllData;

  /// No description provided for @areYouAbsolutelySure.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure?'**
  String get areYouAbsolutelySure;

  /// No description provided for @permanentlyDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all records (Products, Clients, Stock, Invoices, etc). This cannot be undone. Are you sure you want to start fresh?'**
  String get permanentlyDeleteWarning;

  /// No description provided for @wipeEverything.
  ///
  /// In en, this message translates to:
  /// **'WIPE EVERYTHING'**
  String get wipeEverything;

  /// No description provided for @wipingDatabase.
  ///
  /// In en, this message translates to:
  /// **'Wiping database...'**
  String get wipingDatabase;

  /// No description provided for @databaseErasedReset.
  ///
  /// In en, this message translates to:
  /// **'Database completely erased and reset.'**
  String get databaseErasedReset;

  /// No description provided for @recycleBinAdmin.
  ///
  /// In en, this message translates to:
  /// **'Recycle Bin (Admin Only)'**
  String get recycleBinAdmin;

  /// No description provided for @restoreSelected.
  ///
  /// In en, this message translates to:
  /// **'Restore Selected'**
  String get restoreSelected;

  /// No description provided for @selectedItemsRestored.
  ///
  /// In en, this message translates to:
  /// **'Selected items restored successfully.'**
  String get selectedItemsRestored;

  /// No description provided for @permanentlyDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete Selected'**
  String get permanentlyDeleteSelected;

  /// No description provided for @selectedItemsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Selected items deleted permanently.'**
  String get selectedItemsDeleted;

  /// No description provided for @searchRecycleBin.
  ///
  /// In en, this message translates to:
  /// **'Search Recycle Bin'**
  String get searchRecycleBin;

  /// No description provided for @deletedInvoicesBons.
  ///
  /// In en, this message translates to:
  /// **'Deleted Invoices & Bons'**
  String get deletedInvoicesBons;

  /// No description provided for @deletedPurchases.
  ///
  /// In en, this message translates to:
  /// **'Deleted Purchases'**
  String get deletedPurchases;

  /// No description provided for @unknownSupplier.
  ///
  /// In en, this message translates to:
  /// **'Unknown Supplier'**
  String get unknownSupplier;

  /// No description provided for @deletedPaymentsChecks.
  ///
  /// In en, this message translates to:
  /// **'Deleted Payments & Checks'**
  String get deletedPaymentsChecks;

  /// No description provided for @restoreStr.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreStr;

  /// No description provided for @deletePermanentlyStr.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanentlyStr;

  /// No description provided for @clientStr.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get clientStr;

  /// No description provided for @supplierStr.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplierStr;

  /// No description provided for @totalStr.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalStr;

  /// No description provided for @dhsStr.
  ///
  /// In en, this message translates to:
  /// **'Dhs'**
  String get dhsStr;

  /// No description provided for @deleteSelectedDocs.
  ///
  /// In en, this message translates to:
  /// **'Delete Selected Documents'**
  String get deleteSelectedDocs;

  /// No description provided for @selectedDocsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Selected documents deleted.'**
  String get selectedDocsDeleted;

  /// No description provided for @salesAndReturns.
  ///
  /// In en, this message translates to:
  /// **'Sales & Returns'**
  String get salesAndReturns;

  /// No description provided for @searchDocuments.
  ///
  /// In en, this message translates to:
  /// **'Search Documents'**
  String get searchDocuments;

  /// No description provided for @noInvoicesFound.
  ///
  /// In en, this message translates to:
  /// **'No invoices found.'**
  String get noInvoicesFound;

  /// No description provided for @noPurchasesFound.
  ///
  /// In en, this message translates to:
  /// **'No purchases found.'**
  String get noPurchasesFound;

  /// No description provided for @nameOverridesClientName.
  ///
  /// In en, this message translates to:
  /// **'Name (Overrides Client Name in PDF)'**
  String get nameOverridesClientName;

  /// No description provided for @createConsumablesFor.
  ///
  /// In en, this message translates to:
  /// **'Create Consumables for'**
  String get createConsumablesFor;

  /// No description provided for @bottle.
  ///
  /// In en, this message translates to:
  /// **'Bottle'**
  String get bottle;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @consumablesCreatedLinked.
  ///
  /// In en, this message translates to:
  /// **'Consumables created and linked!'**
  String get consumablesCreatedLinked;

  /// No description provided for @productsCatalog.
  ///
  /// In en, this message translates to:
  /// **'Products Catalog'**
  String get productsCatalog;

  /// No description provided for @openingScanner.
  ///
  /// In en, this message translates to:
  /// **'Opening Scanner'**
  String get openingScanner;

  /// No description provided for @noProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No products available.'**
  String get noProductsAvailable;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search Products'**
  String get searchProducts;

  /// No description provided for @tableReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get tableReference;

  /// No description provided for @tablePackaging.
  ///
  /// In en, this message translates to:
  /// **'Packaging'**
  String get tablePackaging;

  /// No description provided for @tableBaseMin.
  ///
  /// In en, this message translates to:
  /// **'Base Min'**
  String get tableBaseMin;

  /// No description provided for @tableMagazinMin.
  ///
  /// In en, this message translates to:
  /// **'Magazin Min'**
  String get tableMagazinMin;

  /// No description provided for @warehouseStock.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Stock'**
  String get warehouseStock;

  /// No description provided for @baseStock.
  ///
  /// In en, this message translates to:
  /// **'Base Stock'**
  String get baseStock;

  /// No description provided for @magazinStock.
  ///
  /// In en, this message translates to:
  /// **'Magazin Stock (Special Client)'**
  String get magazinStock;

  /// No description provided for @scannedStr.
  ///
  /// In en, this message translates to:
  /// **'Scanned:'**
  String get scannedStr;

  /// No description provided for @clearSelectedStockAdmin.
  ///
  /// In en, this message translates to:
  /// **'Clear Selected Stock (Admin)'**
  String get clearSelectedStockAdmin;

  /// No description provided for @noStockInSection.
  ///
  /// In en, this message translates to:
  /// **'No stock in this section.'**
  String get noStockInSection;

  /// No description provided for @baseFamily.
  ///
  /// In en, this message translates to:
  /// **'(Base Family)'**
  String get baseFamily;

  /// No description provided for @refStr.
  ///
  /// In en, this message translates to:
  /// **'Ref'**
  String get refStr;

  /// No description provided for @locStr.
  ///
  /// In en, this message translates to:
  /// **'Loc'**
  String get locStr;

  /// No description provided for @searchStock.
  ///
  /// In en, this message translates to:
  /// **'Search Stock'**
  String get searchStock;

  /// No description provided for @clientsManagement.
  ///
  /// In en, this message translates to:
  /// **'Clients Management'**
  String get clientsManagement;

  /// No description provided for @searchClients.
  ///
  /// In en, this message translates to:
  /// **'Search Clients'**
  String get searchClients;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @noClientsFound.
  ///
  /// In en, this message translates to:
  /// **'No clients found.'**
  String get noClientsFound;

  /// No description provided for @noContactInfo.
  ///
  /// In en, this message translates to:
  /// **'No contact info'**
  String get noContactInfo;

  /// No description provided for @adminAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Admin access required to delete.'**
  String get adminAccessRequired;

  /// No description provided for @suppliersManagement.
  ///
  /// In en, this message translates to:
  /// **'Suppliers Management'**
  String get suppliersManagement;

  /// No description provided for @searchSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Search Suppliers'**
  String get searchSuppliers;

  /// No description provided for @noSuppliersFound.
  ///
  /// In en, this message translates to:
  /// **'No suppliers found.'**
  String get noSuppliersFound;

  /// No description provided for @stockTransfer.
  ///
  /// In en, this message translates to:
  /// **'Stock Transfer'**
  String get stockTransfer;

  /// No description provided for @selectProductAndLocations.
  ///
  /// In en, this message translates to:
  /// **'Please select product and locations'**
  String get selectProductAndLocations;

  /// No description provided for @sourceDestinationSame.
  ///
  /// In en, this message translates to:
  /// **'Source and destination cannot be the same'**
  String get sourceDestinationSame;

  /// No description provided for @transferSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Transfer successful'**
  String get transferSuccessful;

  /// No description provided for @transferFailed.
  ///
  /// In en, this message translates to:
  /// **'Transfer failed: '**
  String get transferFailed;

  /// No description provided for @sourceLocation.
  ///
  /// In en, this message translates to:
  /// **'Source Location'**
  String get sourceLocation;

  /// No description provided for @destinationLocation.
  ///
  /// In en, this message translates to:
  /// **'Destination Location'**
  String get destinationLocation;

  /// No description provided for @mustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Must be greater than 0'**
  String get mustBeGreaterThanZero;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @transferBtn.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferBtn;

  /// No description provided for @addBtn.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addBtn;

  /// No description provided for @nameOverridePdf.
  ///
  /// In en, this message translates to:
  /// **'Name (Overrides Client Name in PDF)'**
  String get nameOverridePdf;

  /// No description provided for @paymentRecordedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded successfully!'**
  String get paymentRecordedSuccessfully;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total: '**
  String get totalLabel;

  /// No description provided for @paidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid: '**
  String get paidLabel;

  /// No description provided for @remainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining: '**
  String get remainingLabel;

  /// No description provided for @paymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Payment Amount'**
  String get paymentAmount;

  /// No description provided for @setToFullRemaining.
  ///
  /// In en, this message translates to:
  /// **'Set to full remaining'**
  String get setToFullRemaining;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @recordBtn.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get recordBtn;

  /// No description provided for @paymentsRecord.
  ///
  /// In en, this message translates to:
  /// **'Payments Record'**
  String get paymentsRecord;

  /// No description provided for @noPaymentsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded.'**
  String get noPaymentsRecorded;

  /// No description provided for @viewCheckImage.
  ///
  /// In en, this message translates to:
  /// **'View Check Image'**
  String get viewCheckImage;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @deletePayment.
  ///
  /// In en, this message translates to:
  /// **'Delete Payment'**
  String get deletePayment;

  /// No description provided for @deletePaymentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Payment?'**
  String get deletePaymentConfirm;

  /// No description provided for @deletePaymentDesc.
  ///
  /// In en, this message translates to:
  /// **'This will algebraically reverse the payment.'**
  String get deletePaymentDesc;

  /// No description provided for @deletedStr.
  ///
  /// In en, this message translates to:
  /// **'DELETED'**
  String get deletedStr;

  /// No description provided for @productLabel.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get productLabel;

  /// No description provided for @invoiceStoppedAt.
  ///
  /// In en, this message translates to:
  /// **'The present invoice is stopped at the sum of :'**
  String get invoiceStoppedAt;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
