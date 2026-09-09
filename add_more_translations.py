import json
import os

arb_dir = '/home/limbo/Desktop/marcoStock/lib/src/localization/arb'
en_file = os.path.join(arb_dir, 'app_en.arb')
ar_file = os.path.join(arb_dir, 'app_ar.arb')

with open(en_file, 'r', encoding='utf-8') as f:
    en_data = json.load(f)

with open(ar_file, 'r', encoding='utf-8') as f:
    ar_data = json.load(f)

more_en = {
    "productNotFound": "Product not found: ",
    "pleaseSelectClientAndProducts": "Please select a client and add products.",
    "saleCompletedSuccessfully": "Sale completed successfully!",
    "newSalePos": "New Sale (POS)",
    "invoice": "Invoice",
    "bon": "Bon",
    "ticket": "Ticket",
    "addPaymentMethod": "Add Payment Method",
    "adjustQuantity": "Adjust Quantity - ",
    "cancel": "Cancel",
    "save": "Save",
    "confirmPayment": "Confirm Payment",
    "productExists": "A Product with this name already exists.",
    "fillRequiredFields": "Please fill all required fields correctly.",
    "selectValidProductForLinked": "Please select a valid product for all linked items.",
    "addNewProduct": "Add New Product",
    "addConsumablesDesc": "Add consumables required to make 1 unit of this product.",
    "addConsumable": "Add Consumable",
    "clientExists": "A Client with this name already exists.",
    "addNewClient": "Add New Client",
    "supplierExists": "A Supplier with this name already exists.",
    "addNewSupplier": "Add New Supplier",
    "employeeExists": "A Employee with this name already exists.",
    "addNewEmployee": "Add New Employee",
    "payrollAction": "Payroll Action: ",
    "issueAdvance": "Issue Advance (Deduct)",
    "issueFinalPayment": "Issue Final Payment (Deduct)",
    "confirm": "Confirm",
    "profileOf": " Profile",
    "noTransactionsFound": "No transactions found."
}

more_ar = {
    "productNotFound": "المنتج غير موجود: ",
    "pleaseSelectClientAndProducts": "الرجاء تحديد عميل وإضافة منتجات.",
    "saleCompletedSuccessfully": "اكتملت عملية البيع بنجاح!",
    "newSalePos": "بيع جديد (نقاط البيع)",
    "invoice": "فاتورة",
    "bon": "بون",
    "ticket": "تذكرة",
    "addPaymentMethod": "إضافة طريقة دفع",
    "adjustQuantity": "تعديل الكمية - ",
    "cancel": "إلغاء",
    "save": "حفظ",
    "confirmPayment": "تأكيد الدفع",
    "productExists": "يوجد منتج بهذا الاسم بالفعل.",
    "fillRequiredFields": "الرجاء تعبئة جميع الحقول المطلوبة بشكل صحيح.",
    "selectValidProductForLinked": "الرجاء تحديد منتج صالح لجميع العناصر المرتبطة.",
    "addNewProduct": "إضافة منتج جديد",
    "addConsumablesDesc": "إضافة المواد الاستهلاكية المطلوبة لصنع وحدة واحدة من هذا المنتج.",
    "addConsumable": "إضافة مادة استهلاكية",
    "clientExists": "يوجد عميل بهذا الاسم بالفعل.",
    "addNewClient": "إضافة عميل جديد",
    "supplierExists": "يوجد مورد بهذا الاسم بالفعل.",
    "addNewSupplier": "إضافة مورد جديد",
    "employeeExists": "يوجد موظف بهذا الاسم بالفعل.",
    "addNewEmployee": "إضافة موظف جديد",
    "payrollAction": "إجراء الرواتب: ",
    "issueAdvance": "صرف سلفة (خصم)",
    "issueFinalPayment": "صرف الدفعة النهائية (خصم)",
    "confirm": "تأكيد",
    "profileOf": " الملف الشخصي",
    "noTransactionsFound": "لم يتم العثور على معاملات."
}

en_data.update(more_en)
ar_data.update(more_ar)

with open(en_file, 'w', encoding='utf-8') as f:
    json.dump(en_data, f, ensure_ascii=False, indent=2)

with open(ar_file, 'w', encoding='utf-8') as f:
    json.dump(ar_data, f, ensure_ascii=False, indent=2)

replacements = {
    "Text('System')": "Text(AppLocalizations.of(context)!.system)",
    "Text('Product not found: $code')": "Text('${AppLocalizations.of(context)!.productNotFound}$code')",
    "Text('Please select a client and add products.')": "Text(AppLocalizations.of(context)!.pleaseSelectClientAndProducts)",
    "Text('Sale completed successfully!')": "Text(AppLocalizations.of(context)!.saleCompletedSuccessfully)",
    "Text('New Sale (POS)')": "Text(AppLocalizations.of(context)!.newSalePos)",
    "Text('Invoice')": "Text(AppLocalizations.of(context)!.invoice)",
    "Text('Bon')": "Text(AppLocalizations.of(context)!.bon)",
    "Text('Ticket')": "Text(AppLocalizations.of(context)!.ticket)",
    "Text('Add Payment Method')": "Text(AppLocalizations.of(context)!.addPaymentMethod)",
    "Text('Adjust Quantity - ${widget.product.name}')": "Text('${AppLocalizations.of(context)!.adjustQuantity}${widget.product.name}')",
    "Text('CANCEL')": "Text(AppLocalizations.of(context)!.cancel.toUpperCase())",
    "Text('SAVE')": "Text(AppLocalizations.of(context)!.save.toUpperCase())",
    "Text('CONFIRM PAYMENT')": "Text(AppLocalizations.of(context)!.confirmPayment.toUpperCase())",
    "Text('A Product with this name already exists.')": "Text(AppLocalizations.of(context)!.productExists)",
    "Text('Please fill all required fields correctly.')": "Text(AppLocalizations.of(context)!.fillRequiredFields)",
    "Text('Please select a valid product for all linked items.')": "Text(AppLocalizations.of(context)!.selectValidProductForLinked)",
    "Text('Add New Product')": "Text(AppLocalizations.of(context)!.addNewProduct)",
    "Text('Add consumables required to make 1 unit of this product.')": "Text(AppLocalizations.of(context)!.addConsumablesDesc)",
    "Text('Add Consumable')": "Text(AppLocalizations.of(context)!.addConsumable)",
    "Text('A Client with this name already exists.')": "Text(AppLocalizations.of(context)!.clientExists)",
    "Text('Add New Client')": "Text(AppLocalizations.of(context)!.addNewClient)",
    "Text('A Supplier with this name already exists.')": "Text(AppLocalizations.of(context)!.supplierExists)",
    "Text('Add New Supplier')": "Text(AppLocalizations.of(context)!.addNewSupplier)",
    "Text('A Employee with this name already exists.')": "Text(AppLocalizations.of(context)!.employeeExists)",
    "Text('Add New Employee')": "Text(AppLocalizations.of(context)!.addNewEmployee)",
    "Text('Payroll Action: ${widget.name}')": "Text('${AppLocalizations.of(context)!.payrollAction}${widget.name}')",
    "Text('Issue Advance (Deduct)')": "Text(AppLocalizations.of(context)!.issueAdvance)",
    "Text('Issue Final Payment (Deduct)')": "Text(AppLocalizations.of(context)!.issueFinalPayment)",
    "Text('Cancel')": "Text(AppLocalizations.of(context)!.cancel)",
    "Text('Confirm')": "Text(AppLocalizations.of(context)!.confirm)",
    "Text('${widget.name} Profile')": "Text('${widget.name}${AppLocalizations.of(context)!.profileOf}')",
    "Text('No transactions found.')": "Text(AppLocalizations.of(context)!.noTransactionsFound)"
}

files_to_process = [
    'lib/src/presentation/layout/main_layout.dart',
    'lib/src/presentation/settings/settings_screen.dart',
    'lib/src/presentation/settings/company_profile_screen.dart',
    'lib/src/presentation/sales/pos_screen.dart',
    'lib/src/presentation/products/add_product_screen.dart',
    'lib/src/presentation/clients/add_client_screen.dart',
    'lib/src/presentation/suppliers/add_supplier_screen.dart',
    'lib/src/presentation/hr/add_employee_screen.dart',
    'lib/src/presentation/widgets/human_profile_dialog.dart',
    'lib/src/presentation/widgets/payment_ledger_dialog.dart'
]

for file_path in files_to_process:
    full_path = os.path.join('/home/limbo/Desktop/marcoStock', file_path)
    if not os.path.exists(full_path):
        continue
    with open(full_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    for old, new in replacements.items():
        content = content.replace(old, new)
        
    with open(full_path, 'w', encoding='utf-8') as f:
        f.write(content)
        
print("Updated more translations.")
