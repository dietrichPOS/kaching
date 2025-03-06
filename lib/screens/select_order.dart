import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kaching/models/orders.dart';
import 'package:kaching/screens/complete_order.dart';
import 'package:kaching/screens/user_number.dart';
import 'package:kaching/styles/app_styles.dart';
import 'package:kaching/widgets/number_entry.dart';
import 'package:kaching/widgets/number_entry_grid.dart';
import 'package:kaching/services/web_service.dart';

class SelectOrderPage extends StatefulWidget {
  const SelectOrderPage({required Key key, required this.ordersDTO})
      : super(key: key);

  final OrdersDto ordersDTO;

  @override
  createState() => _SelectOrderPageState();
}

class _SelectOrderPageState extends State<SelectOrderPage> {
  late List<Order> orders = [];
  late int selectedIndex = -1;

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    super.initState();
    loadData();
  }

  loadData() async {
    debugPrint(widget.ordersDTO.data!.userNo.toString());

    orders.clear();
    if (widget.ordersDTO.data!.orders != null) {
      orders.addAll(widget.ordersDTO.data!.orders!);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();

    return Container(
      constraints: const BoxConstraints.expand(),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Color(0xffff1D2125),
          body: Column(
            children: [
              Container(
                color: Color(0xff1D2125),
                padding: const EdgeInsets.fromLTRB(30, 10, 20, 0).h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0).h,
                        child: Text(
                          '${widget.ordersDTO.data!.userName.toString()} ${widget.ordersDTO.data!.userNo.toString()}',
                          style: AppStyles.mediumTextStyle,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 5).h,
                        child: Text(
                          'SELECT PUMP',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0,
                              fontSize: 18.sp),
                        ),
                      ),
                    ]),
                    Spacer(),
                    Container(
                      alignment: Alignment.topLeft,
                      height: 80.h,
                      padding: EdgeInsets.fromLTRB(20, 10, 0, 15),
                      //color: AppStyles.b,
                      child: Image.asset("assets/images/kachinglogo.png"),
                    ),
                  ],
                ),
              ),
              Expanded(
                  child: Container(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 0).h,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: Container(
                    width: 360.0.w,
                    //height: 100.0,
                    padding: const EdgeInsets.fromLTRB(10, 1, 10, 1).h,
                    decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white10,
                            width: 1,
                          ),
                          top: BorderSide(
                            color: Colors.white10,
                            width: 1,
                          ),
                        ),
                        color: Color.fromARGB(255, 31, 31, 31)),
                    child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: orders.length,
                      itemBuilder: (context, position) {
                        return Container(
                            padding: const EdgeInsets.fromLTRB(0, 10, 0, 0).h,
                            child: ClipRRect(
                                //borderRadius: BorderRadius.horizontal(),
                                child: Container(
                                    width: 350.0.w,
                                    height: 70.w,
                                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0).h,
                                    decoration: BoxDecoration(
                                        color: position == selectedIndex
                                            ? const Color.fromARGB(255, 53, 78, 21)
                                            : const Color.fromARGB(255, 31, 31, 31)),
                                    child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(0),
                                            ),
                                            side: BorderSide(
                                                color: position == selectedIndex
                                                    //? Color(0xFF89bf40)
                                                    ? const Color(0xFF89bf40)
                                                    : const Color(0xFF353535))),
                                        onPressed: () {
                                          debugPrint('$position');
                                          setState(() {
                                            selectedIndex = position;
                                          });
                                        },
                                        child: Row(children: [
                                          Stack(
                                              alignment: Alignment.centerLeft,
                                              children: [
                                                Positioned(
                                                    child: SizedBox(
                                                        width: 30.w,
                                                        height: 30.h,
                                                        child: Center(
                                                          child: Image.asset(
                                                              "assets/images/whitegaspump.png"),
                                                        ))),
                                              ]),
                                          Container(
                                            padding: const EdgeInsets.fromLTRB(
                                                    12, 0, 0, 0)
                                                .h,
                                            child: Text(
                                              orders[position].name ?? '',
                                              style: TextStyle(
                                                  color: Colors.white70,
                                                  fontFamily: 'RobotoCondensed',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18.sp),
                                            ),
                                          ),
                                          Spacer(),
                                          Container(
                                            padding: const EdgeInsets.fromLTRB(
                                                    12, 0, 0, 0)
                                                .h,
                                            child: Text(
                                              orders[position].total.toString(),
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'RobotoCondensed',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18.sp),
                                            ),
                                          ),
                                        ])))));
                      },
                    ),
                    // ],
                    // ),
                  ),
                ),
              ))
            ],
          ),
          bottomNavigationBar:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(15, 15, 5, 15).h,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    backgroundColor: const Color(0x00000000),
                    side: const BorderSide(
                        width: 1.0, color: Color.fromARGB(255, 100, 101, 99))),
                onPressed: () {
                  // if (!hasChangedCourse) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserNumberPage(
                          key: UniqueKey(),
                        ),
                      ));
                },
                child: Container(
                  alignment: Alignment.center,
                  height: 38.h,
                  width: 107.w,
                  child: Text(
                    'BACK',
                    style: TextStyle(
                        color: const Color.fromARGB(255, 100, 101, 99),
                        fontSize: 16.sp,
                        //fontFamily: 'Roboto',
                        letterSpacing: 0,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(5, 15, 15, 15).h,
              child: Opacity(
                opacity: selectedIndex != -1 ? 1 : 0,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      backgroundColor: const Color(0xFF199D36)),
                  onPressed: () async {
                    if (selectedIndex != -1) {
                      if (context.mounted) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CompleteOrderPage(
                                key: UniqueKey(),
                                ordersDTO: widget.ordersDTO,
                                selectedOrderIndex: selectedIndex,
                              ),
                            ));
                      }
                    }
                  },
                  child: Container(
                    alignment: Alignment.center,
                    height: 38.h,
                    width: 107.w,
                    child: Text(
                      'CONFIRM',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          //fontFamily: 'Roboto',
                          letterSpacing: 0,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
