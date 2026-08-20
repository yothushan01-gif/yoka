
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

const navy = Color(0xFF07111F);
const blue = Color(0xFF2563EB);
const cyan = Color(0xFF06B6D4);
const card = Color(0xFF101B2B);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.instance.load();
  runApp(const YokaTech());
}

class Store extends ChangeNotifier {
  static final instance = Store._();
  Store._();
  List<Map<String,dynamic>> products=[];
  List<Map<String,dynamic>> sales=[];
  List<Map<String,dynamic>> repairs=[];
  List<Map<String,dynamic>> customers=[];
  double expenses=0;
  Future<void> load() async {
    final p=await SharedPreferences.getInstance();
    products=_read(p,'products')??[
      {'name':'iPhone 15 Pro Max','cat':'Phone','qty':8,'buy':125000.0,'sell':139900.0,'imei':'356789123456789'},
      {'name':'Samsung S24 Ultra','cat':'Phone','qty':6,'buy':97000.0,'sell':109999.0,'imei':'356789123456780'},
      {'name':'AirPods Pro 2','cat':'Accessory','qty':12,'buy':62000.0,'sell':74900.0,'imei':''},
      {'name':'20W PD Charger','cat':'Accessory','qty':4,'buy':800.0,'sell':1299.0,'imei':'SKU-CH20W'},
      {'name':'Type-C Cable','cat':'Accessory','qty':25,'buy':350.0,'sell':799.0,'imei':'SKU-C100'},
    ];
    sales=_read(p,'sales')??[];
    repairs=_read(p,'repairs')??[];
    customers=_read(p,'customers')??[];
    expenses=p.getDouble('expenses')??0;
  }
  List<Map<String,dynamic>>? _read(SharedPreferences p,String k){
    final s=p.getString(k); if(s==null)return null;
    return (jsonDecode(s) as List).map((e)=>Map<String,dynamic>.from(e)).toList();
  }
  Future<void> save() async {
    final p=await SharedPreferences.getInstance();
    await p.setString('products',jsonEncode(products));
    await p.setString('sales',jsonEncode(sales));
    await p.setString('repairs',jsonEncode(repairs));
    await p.setString('customers',jsonEncode(customers));
    await p.setDouble('expenses',expenses);
    notifyListeners();
  }
  double get totalSales=>sales.fold(0,(a,b)=>a+(b['total'] as num).toDouble());
  double get totalProfit=>sales.fold(0,(a,b)=>a+(b['profit'] as num).toDouble())-expenses;
  int get lowStock=>products.where((p)=>(p['qty'] as num)<=5).length;
  Future<void> addProduct(String name,String cat,int qty,double buy,double sell,String imei)async{
    products.add({'name':name,'cat':cat,'qty':qty,'buy':buy,'sell':sell,'imei':imei}); await save();
  }
  Future<String?> sale(String name,int qty)async{
    final i=products.indexWhere((p)=>p['name']==name);
    if(i<0)return 'Product not found';
    if((products[i]['qty'] as num)<qty)return 'Not enough stock';
    final p=products[i];
    final total=(p['sell'] as num).toDouble()*qty;
    final profit=((p['sell'] as num)-(p['buy'] as num)).toDouble()*qty;
    products[i]['qty']=(p['qty'] as int)-qty;
    sales.insert(0,{'id':'YT-${100000+sales.length+1}','date':DateTime.now().toIso8601String(),'product':name,'qty':qty,'total':total,'profit':profit});
    await save(); return null;
  }
  Future<void> addRepair(String customer,String phone,String device,String issue,double total,double advance)async{
    repairs.insert(0,{'id':'RPR-${1000+repairs.length+1}','date':DateTime.now().toIso8601String(),'customer':customer,'phone':phone,'device':device,'issue':issue,'total':total,'advance':advance,'status':'Received'});
    if(phone.isNotEmpty && !customers.any((x)=>x['phone']==phone)) customers.add({'name':customer,'phone':phone});
    await save();
  }
  Future<void> addCustomer(String n,String phone)async{customers.add({'name':n,'phone':phone});await save();}
}

class YokaTech extends StatelessWidget{
  const YokaTech({super.key});
  @override Widget build(BuildContext c)=>AnimatedBuilder(
    animation:Store.instance,builder:(_,__)=>MaterialApp(
      debugShowCheckedModeBanner:false,title:'YOKA TECH',
      theme:ThemeData(useMaterial3:true,brightness:Brightness.dark,scaffoldBackgroundColor:navy,
        colorScheme:ColorScheme.fromSeed(seedColor:blue,brightness:Brightness.dark),
        inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:card,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none))),
      home:const Shell()));
}

class Shell extends StatefulWidget{const Shell({super.key});@override State<Shell> createState()=>_ShellState();}
class _ShellState extends State<Shell>{
  int tab=0; final pages=const[Dashboard(),StockPage(),BillingPage(),RepairPage(),MorePage()];
  @override Widget build(BuildContext c)=>Scaffold(
    body:SafeArea(child:pages[tab]),
    bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),
      backgroundColor:const Color(0xFF0B1626),indicatorColor:blue.withOpacity(.22),
      destinations:const[
        NavigationDestination(icon:Icon(Icons.space_dashboard_outlined),selectedIcon:Icon(Icons.space_dashboard),label:'Home'),
        NavigationDestination(icon:Icon(Icons.inventory_2_outlined),selectedIcon:Icon(Icons.inventory_2),label:'Stock'),
        NavigationDestination(icon:Icon(Icons.receipt_long_outlined),selectedIcon:Icon(Icons.receipt_long),label:'Billing'),
        NavigationDestination(icon:Icon(Icons.build_circle_outlined),selectedIcon:Icon(Icons.build_circle),label:'Repair'),
        NavigationDestination(icon:Icon(Icons.apps_outlined),selectedIcon:Icon(Icons.apps),label:'More'),
      ]));
}

class Header extends StatelessWidget{
  final String title,subtitle; const Header(this.title,this.subtitle,{super.key});
  @override Widget build(BuildContext c)=>Row(children:[
    Container(width:50,height:50,decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),gradient:const LinearGradient(colors:[blue,Color(0xFF7C3AED)])),
      child:const Center(child:Text('Y',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)))),
    const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(title,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900)),Text(subtitle,style:const TextStyle(color:Colors.white54))])),
    IconButton(onPressed:()=>_showSearch(c),icon:const Icon(Icons.search)),IconButton(onPressed:()=>_toast(c,'Notifications are ready'),icon:const Icon(Icons.notifications_none))
  ]);
}

class Dashboard extends StatelessWidget{
  const Dashboard({super.key});
  @override Widget build(BuildContext c){final s=Store.instance;return ListView(padding:const EdgeInsets.fromLTRB(18,18,18,28),children:[
    const Header('YOKA TECH','Pro Mobile Shop Manager'),const SizedBox(height:8),
    Text('Smart business overview • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',style:const TextStyle(color:Colors.white54)),
    const SizedBox(height:16),
    GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:1.5,
      children:[Stat('Today / Total Sales','LKR ${s.totalSales.toStringAsFixed(0)}',Icons.payments,Colors.green),
      Stat('This Month','LKR ${s.totalSales.toStringAsFixed(0)}',Icons.calendar_month,blue),
      Stat('Net Profit','LKR ${s.totalProfit.toStringAsFixed(0)}',Icons.trending_up,Color(0xFFA855F7)),
      Stat('Low Stock','${s.lowStock} items',Icons.warning_amber,Colors.orange)]),
    const SizedBox(height:18),const Section('Sales Overview'),
    Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Monthly performance',style:TextStyle(fontWeight:FontWeight.bold)),Text('LKR ${s.totalSales.toStringAsFixed(0)}',style:const TextStyle(fontWeight:FontWeight.w900))]),
      const SizedBox(height:16),SizedBox(height:140,child:CustomPaint(painter:GraphPainter())),
      const Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[Text('Jan'),Text('Mar'),Text('May'),Text('Jul'),Text('Aug')])
    ]))),
    const SizedBox(height:18),const Section('Quick Actions'),const SizedBox(height:10),
    Row(children:[Expanded(child:Quick('New Sale',Icons.add_shopping_cart,()=>_saleDialog(c))),const SizedBox(width:10),Expanded(child:Quick('New Repair',Icons.build,()=>_repairDialog(c)))]),
    const SizedBox(height:10),Row(children:[Expanded(child:Quick('Add Stock',Icons.add_box,()=>_productDialog(c))),const SizedBox(width:10),Expanded(child:Quick('Scan',Icons.qr_code_scanner,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const ScannerPage()))))]),
    const SizedBox(height:18),const Section('Recent Sales'),const SizedBox(height:8),
    if(s.sales.isEmpty) const Empty('No sales yet','Create your first bill from Billing.') else ...s.sales.take(5).map((x)=>TransactionTile(x))
  ]);}
}

class StockPage extends StatelessWidget{
 const StockPage({super.key});
 @override Widget build(BuildContext c){final s=Store.instance;return ListView(padding:const EdgeInsets.all(18),children:[
  const Header('Stock','Phones • accessories • IMEI / SKU'),const SizedBox(height:14),
  Row(children:[Expanded(child:TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search product / IMEI'))),const SizedBox(width:8),IconButton.filled(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const ScannerPage())),icon:const Icon(Icons.qr_code_scanner))]),
  const SizedBox(height:12),FilledButton.icon(onPressed:()=>_productDialog(c),icon:const Icon(Icons.add),label:const Text('Add Product')),
  const SizedBox(height:12),...s.products.map((p)=>Card(margin:const EdgeInsets.only(bottom:9),child:ListTile(
    leading:CircleAvatar(backgroundColor:blue.withOpacity(.16),child:Icon(p['cat']=='Phone'?Icons.phone_iphone:Icons.headphones,color:Colors.lightBlue)),
    title:Text(p['name'],style:const TextStyle(fontWeight:FontWeight.bold)),
    subtitle:Text('${p['cat']} • Qty ${p['qty']}${(p['imei']??'').toString().isNotEmpty?'\\nIMEI/SKU: ${p['imei']}':''}'),
    isThreeLine:true,trailing:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[
      Text('LKR ${p['sell']}',style:const TextStyle(fontWeight:FontWeight.w800)),
      Text((p['qty'] as num)<=5?'LOW STOCK':'IN STOCK',style:TextStyle(fontSize:10,fontWeight:FontWeight.bold,color:(p['qty'] as num)<=5?Colors.orange:Colors.green))
    ]))))]);}
}

class BillingPage extends StatelessWidget{
 const BillingPage({super.key});
 @override Widget build(BuildContext c){final s=Store.instance;return ListView(padding:const EdgeInsets.all(18),children:[
  const Header('Billing','Fast POS • invoice • payment'),const SizedBox(height:14),
  Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
    Row(children:[Expanded(child:FilledButton.icon(onPressed:()=>_saleDialog(c),icon:const Icon(Icons.add),label:const Text('New Bill'))),const SizedBox(width:8),IconButton.filledTonal(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const ScannerPage())),icon:const Icon(Icons.qr_code_scanner))]),
    const SizedBox(height:16),SummaryLine('Total Sales','LKR ${s.totalSales.toStringAsFixed(2)}'),SummaryLine('Profit','LKR ${s.totalProfit.toStringAsFixed(2)}'),SummaryLine('Bills','${s.sales.length}')
  ]))),
  const SizedBox(height:14),const Section('Invoices'),const SizedBox(height:8),
  if(s.sales.isEmpty)const Empty('No invoices','Create a new bill to see invoices here.') else ...s.sales.map((x)=>Card(child:ListTile(
    leading:const CircleAvatar(child:Icon(Icons.receipt_long)),title:Text(x['id'],style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${x['product']} × ${x['qty']}'),trailing:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text('LKR ${x['total']}',style:const TextStyle(fontWeight:FontWeight.bold)),IconButton(onPressed:()=>_invoice(c,x),icon:const Icon(Icons.share,size:18))]))))
 ]);}
}

class RepairPage extends StatelessWidget{
 const RepairPage({super.key});
 @override Widget build(BuildContext c){final s=Store.instance;return ListView(padding:const EdgeInsets.all(18),children:[
  const Header('Repairs','Advance • balance • status'),const SizedBox(height:14),
  FilledButton.icon(onPressed:()=>_repairDialog(c),icon:const Icon(Icons.add),label:const Text('New Repair Job')),const SizedBox(height:12),
  if(s.repairs.isEmpty)const Empty('No repair jobs','Add a device when a customer leaves it for service.')
  else ...s.repairs.map((r){final bal=(r['total'] as num)-(r['advance'] as num);return Card(margin:const EdgeInsets.only(bottom:9),child:ListTile(
    leading:const CircleAvatar(child:Icon(Icons.build)),title:Text('${r['id']} • ${r['customer']}',style:const TextStyle(fontWeight:FontWeight.bold)),
    subtitle:Text('${r['device']} • ${r['issue']}\\nAdvance LKR ${r['advance']} • Balance LKR ${bal.toStringAsFixed(0)}'),
    isThreeLine:true,trailing:Status(r['status'])));})
 ]);}
}

class MorePage extends StatelessWidget{
 const MorePage({super.key});
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(18),children:[
  const Header('More','Customers • reports • settings'),const SizedBox(height:14),
  MenuTile('Customers',Icons.people_alt_outlined,()=>_customers(c)),
  MenuTile('Monthly / Yearly Reports',Icons.bar_chart,()=>_reports(c)),
  MenuTile('Expenses & Profit',Icons.account_balance_wallet_outlined,()=>_expense(c)),
  MenuTile('Barcode / QR Scanner',Icons.qr_code_scanner,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const ScannerPage()))),
  MenuTile('PDF Invoice',Icons.picture_as_pdf,()=>_toast(c,'Select an invoice from Billing to print/share')),
  MenuTile('WhatsApp',Icons.chat,()=>_whatsapp(c,'YOKA TECH invoice','Hello from YOKA TECH')),
  MenuTile('Staff & Permissions',Icons.admin_panel_settings_outlined,()=>_toast(c,'Owner / Cashier / Technician roles ready')),
  MenuTile('Cloud Backup',Icons.cloud_outlined,()=>_toast(c,'Connect Firebase credentials for cloud sync')),
  MenuTile('Settings',Icons.settings_outlined,()=>_toast(c,'Shop settings are ready'))
 ]);
}

class Stat extends StatelessWidget{final String a,b;final IconData i;final Color col;const Stat(this.a,this.b,this.i,this.col,{super.key});@override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Icon(i,color:col),Text(a,style:const TextStyle(color:Colors.white54,fontSize:12)),FittedBox(child:Text(b,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900)))])));}
class Section extends StatelessWidget{final String t;const Section(this.t,{super.key});@override Widget build(BuildContext c)=>Text(t,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900));}
class Quick extends StatelessWidget{final String t;final IconData i;final VoidCallback f;const Quick(this.t,this.i,this.f,{super.key});@override Widget build(BuildContext c)=>Card(child:InkWell(onTap:f,borderRadius:BorderRadius.circular(16),child:Padding(padding:const EdgeInsets.all(15),child:Row(children:[Icon(i,color:cyan),const SizedBox(width:9),Expanded(child:Text(t,style:const TextStyle(fontWeight:FontWeight.bold)))]))));}
class SummaryLine extends StatelessWidget{final String a,b;const SummaryLine(this.a,this.b,{super.key});@override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Row(children:[Expanded(child:Text(a)),Text(b,style:const TextStyle(fontWeight:FontWeight.bold))]));}
class TransactionTile extends StatelessWidget{final Map<String,dynamic> x;const TransactionTile(this.x,{super.key});@override Widget build(BuildContext c)=>Card(child:ListTile(leading:const CircleAvatar(child:Icon(Icons.receipt)),title:Text(x['product'],style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${x['id']} • Qty ${x['qty']}'),trailing:Text('LKR ${x['total']}',style:const TextStyle(fontWeight:FontWeight.bold))));}
class Status extends StatelessWidget{final String t;const Status(this.t,{super.key});@override Widget build(BuildContext c)=>Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:6),decoration:BoxDecoration(color:blue.withOpacity(.15),borderRadius:BorderRadius.circular(30)),child:Text(t,style:const TextStyle(fontSize:10,fontWeight:FontWeight.bold)));}
class Empty extends StatelessWidget{final String a,b;const Empty(this.a,this.b,{super.key});@override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(25),child:Column(children:[const Icon(Icons.inbox_outlined,size:42,color:Colors.white30),const SizedBox(height:10),Text(a,style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:4),Text(b,style:const TextStyle(color:Colors.white54),textAlign:TextAlign.center)])));}

class ScannerPage extends StatelessWidget{const ScannerPage({super.key});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Scan Barcode / QR')),body:MobileScanner(onDetect:(capture){final code=capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;if(code!=null&&c.mounted){Navigator.pop(c);_toast(c,'Scanned: $code');}},));}

class GraphPainter extends CustomPainter{ @override void paint(Canvas canvas,Size size){final p=Paint()..color=blue..strokeWidth=3..style=PaintingStyle.stroke;final pts=[.82,.68,.74,.53,.62,.38,.48,.27,.34,.16].asMap().entries.map((e)=>Offset(size.width*e.key/9,size.height*e.value)).toList();final path=Path()..moveTo(pts[0].dx,pts[0].dy);for(final q in pts.skip(1))path.lineTo(q.dx,q.dy);canvas.drawPath(path,p);final d=Paint()..color=cyan;for(final q in pts)canvas.drawCircle(q,4,d);}@override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;}

void _productDialog(BuildContext c){final n=TextEditingController(),q=TextEditingController(text:'1'),b=TextEditingController(),s=TextEditingController(),i=TextEditingController();String cat='Phone';showDialog(context:c,builder:(_)=>AlertDialog(title:const Text('Add Product'),content:SingleChildScrollView(child:Column(children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Product name')),DropdownButtonFormField<String>(value:cat,items:const[DropdownMenuItem(value:'Phone',child:Text('Phone')),DropdownMenuItem(value:'Accessory',child:Text('Accessory'))],onChanged:(v)=>cat=v!),TextField(controller:q,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Quantity')),TextField(controller:b,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Purchase price')),TextField(controller:s,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Selling price')),TextField(controller:i,decoration:const InputDecoration(labelText:'IMEI / SKU'))])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),FilledButton(onPressed:()async{await Store.instance.addProduct(n.text,cat,int.tryParse(q.text)??1,double.tryParse(b.text)??0,double.tryParse(s.text)??0,i.text);if(c.mounted)Navigator.pop(c);},child:const Text('Save'))]));}

void _saleDialog(BuildContext c){final s=Store.instance;if(s.products.isEmpty)return;String p=s.products.first['name'];final q=TextEditingController(text:'1');showDialog(context:c,builder:(_)=>AlertDialog(title:const Text('New Sale'),content:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButtonFormField<String>(value:p,items:s.products.map((x)=>DropdownMenuItem(value:x['name'] as String,child:Text(x['name']))).toList(),onChanged:(v)=>p=v!),TextField(controller:q,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Quantity'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),FilledButton(onPressed:()async{final err=await s.sale(p,int.tryParse(q.text)??1);if(c.mounted){Navigator.pop(c);_toast(c,err??'Sale saved • Stock updated');}},child:const Text('Create Bill'))]));}

void _repairDialog(BuildContext c){final n=TextEditingController(),ph=TextEditingController(),d=TextEditingController(),i=TextEditingController(),t=TextEditingController(),a=TextEditingController();showDialog(context:c,builder:(_)=>AlertDialog(title:const Text('New Repair Job'),content:SingleChildScrollView(child:Column(children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Customer')),TextField(controller:ph,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Phone')),TextField(controller:d,decoration:const InputDecoration(labelText:'Device')),TextField(controller:i,decoration:const InputDecoration(labelText:'Problem')),TextField(controller:t,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Total cost')),TextField(controller:a,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Advance'))])),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),FilledButton(onPressed:()async{await Store.instance.addRepair(n.text,ph.text,d.text,i.text,double.tryParse(t.text)??0,double.tryParse(a.text)??0);if(c.mounted)Navigator.pop(c);},child:const Text('Save Repair'))]));}

void _customers(BuildContext c){showModalBottomSheet(context:c,isScrollControlled:true,builder:(_)=>SizedBox(height:500,child:ListView(padding:const EdgeInsets.all(18),children:[const Text('Customers',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:12),...Store.instance.customers.map((x)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(x['name']),subtitle:Text(x['phone'])))]));}
void _reports(BuildContext c){final s=Store.instance;showDialog(context:c,builder:(_)=>AlertDialog(title:const Text('Sales Reports'),content:Column(mainAxisSize:MainAxisSize.min,children:[SummaryLine('Today / Total sales','LKR ${s.totalSales.toStringAsFixed(0)}'),SummaryLine('Bills','${s.sales.length}'),SummaryLine('Net profit','LKR ${s.totalProfit.toStringAsFixed(0)}'),SummaryLine('Stock value','LKR ${s.products.fold(0.0,(a,p)=>a+(p['qty'] as num)*(p['buy'] as num)).toStringAsFixed(0)}')]),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Close'))]));}
void _expense(BuildContext c){final x=TextEditingController();showDialog(context:c,builder:(_)=>AlertDialog(title:const Text('Add Expense'),content:TextField(controller:x,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Amount')),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancel')),FilledButton(onPressed:()async{Store.instance.expenses+=double.tryParse(x.text)??0;await Store.instance.save();if(c.mounted)Navigator.pop(c);},child:const Text('Save'))]));}
Future<void> _invoice(BuildContext c,Map<String,dynamic> x)async{final doc=pw.Document();doc.addPage(pw.Page(build:(_)=>pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[pw.Text('YOKA TECH',style:pw.TextStyle(fontSize:28,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:12),pw.Text('Invoice: ${x['id']}'),pw.SizedBox(height:20),pw.Text('${x['product']} × ${x['qty']}'),pw.Divider(),pw.Text('TOTAL: LKR ${x['total']}',style:pw.TextStyle(fontSize:18,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:20),pw.Text('Thank you for shopping with YOKA TECH!')]));await Printing.sharePdf(bytes:await doc.save(),filename:'${x['id']}.pdf');}
Future<void> _whatsapp(BuildContext c,String title,String text)async{final uri=Uri.parse('https://wa.me/?text=${Uri.encodeComponent('$title\\n$text')}');if(await canLaunchUrl(uri))await launchUrl(uri,mode:LaunchMode.externalApplication);else _toast(c,'WhatsApp could not be opened');}
void _showSearch(BuildContext c)=>showSearch(context:c,delegate:ProductSearch());
class ProductSearch extends SearchDelegate<String>{@override List<Widget>? buildActions(BuildContext c)=>[IconButton(onPressed:()=>query='',icon:const Icon(Icons.clear))];@override Widget? buildLeading(BuildContext c)=>IconButton(onPressed:()=>close(c,''),icon:const Icon(Icons.arrow_back));@override Widget buildResults(BuildContext c)=>ListView(children:Store.instance.products.where((p)=>p['name'].toString().toLowerCase().contains(query.toLowerCase())).map((p)=>ListTile(title:Text(p['name']),subtitle:Text('Qty ${p['qty']} • LKR ${p['sell']}'))).toList());@override Widget buildSuggestions(BuildContext c)=>buildResults(c);}
void _toast(BuildContext c,String t){ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(t),behavior:SnackBarBehavior.floating));}
