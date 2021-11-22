import 'package:daily_log/HomePage.dart';
import 'package:daily_log/MenuBottom.dart';
import 'package:daily_log/NotificationWidget.dart';
import 'package:daily_log/ProfilStatus.dart';
import 'package:daily_log/api/ApiService.dart';
import 'package:daily_log/model/Pekerjaan.dart';
import 'package:daily_log/model/PekerjaanResponse.dart';
import 'package:daily_log/model/SubPekerjaan.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PekerjaanHarianPage extends StatefulWidget {
  final int idUser;
  const PekerjaanHarianPage({Key? key, required this.idUser}) : super(key: key);

  @override
  _PekerjaanHarianPageState createState() => _PekerjaanHarianPageState();
}

class _PekerjaanHarianPageState extends State<PekerjaanHarianPage> {
  late Future<PekerjaanResponse> pekerjaanResponse;
  List<List<SubPekerjaan>> mapPekerjaan = [];
  int idAtasan = 0;
  DateTime dateFilled = DateTime.now();

  @override
  void initState() {
    super.initState();
    pekerjaanResponse = ApiService().getPekerjaan(widget.idUser);
  }

  getLoginData() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      idAtasan = sharedPreferences.getInt("atasan_id")!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pekerjaan Harian"),
        actions: [NotificationWidget()],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfilStatus(),
            SizedBox(
              height: 8,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.only(left: 16, top: 8),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Tupoksi",
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 16),
                  child: ElevatedButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            lastDate: DateTime.now(),
                            firstDate:
                                DateTime.now().subtract(Duration(days: 2)));
                        if (date != null) {
                          setState(() {
                            dateFilled = date;
                          });
                        }
                      },
                      child: Text(DateFormat("dd/MM/yyyy").format(dateFilled))),
                )
              ],
            ),
            SizedBox(height: 16),
            FutureBuilder<PekerjaanResponse>(
                future: pekerjaanResponse,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var listPekerjaan = snapshot.data;
                    List<Pekerjaan> items = listPekerjaan!.data;
                    if (items.length > 0) {
                      mapPekerjaan.clear();
                      return ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          mapPekerjaan.add([
                            newSubPekerjaan(
                                items[index].id, widget.idUser, dateFilled)
                          ]);
                          return PekerjaanListWidget(
                            headerText: items[index].nama,
                            idPekerjaan: items[index].id,
                            listSubPekerjaan: mapPekerjaan[index],
                            idUser: widget.idUser,
                            dateFilled: dateFilled,
                          );
                        },
                        itemCount: items.length,
                      );
                    } else {
                      return Center(
                        child: Text("No Data"),
                      );
                    }
                  } else if (snapshot.hasError) {
                    return Text("Error");
                  }

                  return CircularProgressIndicator();
                }),
            Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: MaterialButton(
                onPressed: () async {
                  mapPekerjaan.forEach((element) {
                    element.forEach((element) {
                      print(element.nama);
                      ApiService().submitSubPekerjaan(element);
                      ApiService().createSubmitNotif(
                          idAtasan, element.id, widget.idUser);
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) {
                        return HomePage();
                      }));
                    });
                  });
                },
                height: 56,
                minWidth: 96,
                color: Colors.blue,
                textColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Text(
                  "SUBMIT",
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            SizedBox(
              height: 52,
            )
          ],
        ),
      ),
      bottomNavigationBar: MenuBottom(),
    );
  }
}

class PekerjaanListWidget extends StatefulWidget {
  final int idUser;
  final String headerText;
  final int idPekerjaan;
  final List<SubPekerjaan> listSubPekerjaan;
  final DateTime dateFilled;
  const PekerjaanListWidget(
      {Key? key,
      required this.headerText,
      required this.idPekerjaan,
      required this.listSubPekerjaan,
      required this.idUser,
      required this.dateFilled})
      : super(key: key);

  @override
  _PekerjaanListWidgetState createState() => _PekerjaanListWidgetState();
}

class _PekerjaanListWidgetState extends State<PekerjaanListWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: ExpansionTile(
        maintainState: true,
        title: Text(widget.headerText),
        children: [
          ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: widget.listSubPekerjaan.length,
              itemBuilder: (context, index) {
                return InputPekerjaanWidget(
                  subPekerjaan: widget.listSubPekerjaan[index],
                );
              }),
          Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: MaterialButton(
              onPressed: () {
                setState(() {
                  widget.listSubPekerjaan.add(newSubPekerjaan(
                      widget.idPekerjaan, widget.idUser, widget.dateFilled));
                });
              },
              height: 56,
              minWidth: 96,
              color: Colors.blue,
              textColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Text(
                "TAMBAH",
                style: TextStyle(fontSize: 14),
              ),
            ),
          )
        ],
      ),
    );
  }
}

SubPekerjaan newSubPekerjaan(int idPekerjaan, int idUser, DateTime dateFilled) {
  DateTime date = DateTime.now();
  String selectDate = DateFormat("yyyy-MM-dd").format(dateFilled);
  String formatDate = DateFormat("HH:mm:ss").format(date);
  print("tes $selectDate $formatDate");
  return SubPekerjaan(
      idPekerjaan: idPekerjaan,
      tanggal: "$selectDate $formatDate",
      status: 'submit',
      idUser: idUser);
}

class InputPekerjaanWidget extends StatefulWidget {
  final SubPekerjaan subPekerjaan;
  const InputPekerjaanWidget({Key? key, required this.subPekerjaan})
      : super(key: key);

  @override
  _InputPekerjaanWidgetState createState() => _InputPekerjaanWidgetState();
}

class _InputPekerjaanWidgetState extends State<InputPekerjaanWidget> {
  String duration = "00:00";
  int jam = 0;
  int menit = 0;
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
  }

  currentJamValue(value) {
    setState(() {
      jam = value;
      // widget.subPekerjaan.durasi = jam;
    });
  }

  currentMenitValue(value) {
    setState(() {
      menit = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Detail Pekerjaan"),
          Container(
            child: TextFormField(
              onChanged: (value) => widget.subPekerjaan.nama = value,
              controller: _textEditingController,
              decoration: InputDecoration(
                  hintText: "Detail Pekerjaan",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Text("Durasi"),
          GestureDetector(
            child: Container(
              child: IntrinsicWidth(
                child: TextFormField(
                  enabled: false,
                  decoration: InputDecoration(
                      hintText: duration,
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                ),
              ),
            ),
            onTap: () async {
              return await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: Container(
                        height: 200,
                        width: 300,
                        child: CupertinoTimerPicker(
                          onTimerDurationChanged: (duration) => {
                            currentJamValue(duration.inHours),
                            currentMenitValue(duration.inMinutes % 60)
                          },
                          mode: CupertinoTimerPickerMode.hm,
                        ),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () {
                              setState(() => duration =
                                  menit < 9 ? "0$jam:0$menit" : "0$jam:$menit");
                              widget.subPekerjaan.durasi = (jam * 60) + menit;
                              Navigator.of(context).pop();
                            },
                            child: Text("OK")),
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text("BATAL"))
                      ],
                    );
                  });
            },
          )
        ],
      ),
    );
  }
}
