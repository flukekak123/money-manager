// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'Money Manager';

  @override
  String get navHome => 'หน้าแรก';

  @override
  String get navTransactions => 'รายการ';

  @override
  String get navBudgets => 'งบประมาณ';

  @override
  String get navReports => 'รายงาน';

  @override
  String get navSettings => 'ตั้งค่า';

  @override
  String get add => 'เพิ่ม';

  @override
  String get recent => 'ล่าสุด';

  @override
  String get thisMonth => 'เดือนนี้';

  @override
  String get income => 'รายรับ';

  @override
  String get expense => 'รายจ่าย';

  @override
  String get balance => 'คงเหลือ';

  @override
  String get net => 'สุทธิ';

  @override
  String get category => 'หมวดหมู่';

  @override
  String get noTransactionsYet => 'ยังไม่มีรายการ';

  @override
  String get tapAddToRecord => 'แตะ เพิ่ม เพื่อบันทึกรายรับหรือรายจ่าย';

  @override
  String get tapAddFirst => 'แตะ เพิ่ม เพื่อบันทึกรายการแรกของคุณ';

  @override
  String errorWithMessage(Object message) {
    return 'ข้อผิดพลาด: $message';
  }

  @override
  String get deleteTransactionTitle => 'ลบรายการนี้?';

  @override
  String get cannotBeUndone => 'การกระทำนี้ไม่สามารถย้อนกลับได้';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get delete => 'ลบ';

  @override
  String get save => 'บันทึก';

  @override
  String get editTransaction => 'แก้ไขรายการ';

  @override
  String get addTransaction => 'เพิ่มรายการ';

  @override
  String get amount => 'จำนวนเงิน';

  @override
  String get enterAmount => 'กรอกจำนวนเงิน';

  @override
  String get selectCategory => 'เลือกหมวดหมู่';

  @override
  String get wallet => 'กระเป๋าเงิน';

  @override
  String get selectWallet => 'เลือกกระเป๋าเงิน';

  @override
  String get noteOptional => 'หมายเหตุ (ไม่บังคับ)';

  @override
  String get selectCategoryAndWallet => 'เลือกหมวดหมู่และกระเป๋าเงิน';

  @override
  String get noBudgets => 'ไม่มีงบประมาณสำหรับเดือนนี้';

  @override
  String get tapPlusBudget => 'แตะ + เพื่อตั้งวงเงินรายเดือนของหมวดหมู่';

  @override
  String get addUpdateBudget => 'เพิ่ม / แก้ไขงบประมาณ';

  @override
  String get budget => 'งบประมาณ';

  @override
  String get monthlyLimit => 'วงเงินต่อเดือน';

  @override
  String get over => 'เกิน';

  @override
  String get spendingByCategory => 'รายจ่ายตามหมวดหมู่';

  @override
  String get noExpensesThisMonth => 'ไม่มีรายจ่ายในเดือนนี้';

  @override
  String get incomeVsExpense => 'รายรับเทียบรายจ่าย';

  @override
  String get noDataThisMonth => 'ไม่มีข้อมูลในเดือนนี้';

  @override
  String get categories => 'หมวดหมู่';

  @override
  String get newCategory => 'หมวดหมู่ใหม่';

  @override
  String get editCategory => 'แก้ไขหมวดหมู่';

  @override
  String get name => 'ชื่อ';

  @override
  String get defaultLabel => 'ค่าเริ่มต้น';

  @override
  String get wallets => 'กระเป๋าเงิน';

  @override
  String get newWallet => 'กระเป๋าเงินใหม่';

  @override
  String get editWallet => 'แก้ไขกระเป๋าเงิน';

  @override
  String get type => 'ประเภท';

  @override
  String get archive => 'เก็บเข้าคลัง';

  @override
  String get manage => 'จัดการ';

  @override
  String get preferences => 'การตั้งค่า';

  @override
  String get currency => 'สกุลเงิน';

  @override
  String get theme => 'ธีม';

  @override
  String get language => 'ภาษา';

  @override
  String get appLock => 'ล็อกแอป';

  @override
  String get appLockSubtitle => 'ต้องปลดล็อกด้วยไบโอเมตริก/อุปกรณ์เมื่อเปิดแอป';

  @override
  String get dataSection => 'ข้อมูล';

  @override
  String get exportData => 'ส่งออกข้อมูล';

  @override
  String get exportDataSubtitle => 'บันทึกไฟล์สำรอง JSON ของข้อมูลทั้งหมด';

  @override
  String get importData => 'นำเข้าข้อมูล';

  @override
  String get importDataSubtitle =>
      'กู้คืนจากไฟล์สำรอง JSON (แทนที่ข้อมูลทั้งหมด)';

  @override
  String get backupExported => 'ส่งออกข้อมูลสำรองแล้ว';

  @override
  String get backupRestored => 'กู้คืนข้อมูลสำรองแล้ว';

  @override
  String exportFailed(Object message) {
    return 'ส่งออกไม่สำเร็จ: $message';
  }

  @override
  String importFailed(Object message) {
    return 'นำเข้าไม่สำเร็จ: $message';
  }

  @override
  String get replaceAllData => 'แทนที่ข้อมูลทั้งหมด?';

  @override
  String get replaceAllDataBody =>
      'การนำเข้าไฟล์สำรองจะแทนที่กระเป๋าเงิน หมวดหมู่ รายการ และงบประมาณทั้งหมดอย่างถาวร ไม่สามารถย้อนกลับได้';

  @override
  String get replace => 'แทนที่';

  @override
  String get aboutBody =>
      'แอปการเงินส่วนบุคคลแบบออฟไลน์ ข้อมูลเก็บอยู่บนอุปกรณ์';

  @override
  String get appLockedTitle => 'Money Manager ถูกล็อกอยู่';

  @override
  String get unlock => 'ปลดล็อก';

  @override
  String get themeSystem => 'ตามระบบ';

  @override
  String get themeLight => 'สว่าง';

  @override
  String get themeDark => 'มืด';

  @override
  String get payInInstallments => 'ผ่อนชำระ';

  @override
  String get installmentMonthsLabel => 'จำนวนเดือน';

  @override
  String installmentPreview(Object months, Object amount, Object lastAmount) {
    return 'ผ่อน $months งวด งวดละ $amount (งวดสุดท้าย $lastAmount)';
  }

  @override
  String get installmentPlanTitle => 'แผนผ่อนชำระ';

  @override
  String installmentProgress(Object paid, Object total) {
    return 'ชำระแล้ว $paid จาก $total งวด';
  }

  @override
  String installmentNoLabel(Object no) {
    return 'งวดที่ $no';
  }

  @override
  String installmentCreated(Object months) {
    return 'สร้างแผนผ่อนชำระแล้ว ($months งวด)';
  }

  @override
  String get total => 'ยอดรวม';

  @override
  String get deletePlan => 'ลบแผนผ่อน';

  @override
  String deletePlanBody(Object count) {
    return 'จะลบรายการผ่อนทั้งหมด $count รายการ และไม่สามารถย้อนกลับได้';
  }

  @override
  String get walletTypeCash => 'เงินสด';

  @override
  String get walletTypeBank => 'ธนาคาร';

  @override
  String get walletTypeCard => 'บัตร';

  @override
  String get walletTypeOther => 'อื่น ๆ';
}
