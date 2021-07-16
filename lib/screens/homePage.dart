import 'dart:io';
import 'package:envoy/models.dart/orderJsonModel.dart';
import 'package:envoy/models.dart/userJsonModel.dart';
import 'package:envoy/screens/loginPage.dart';
import 'package:envoy/screens/orderDetailPage.dart';
import 'package:envoy/settings/consts.dart';
import 'package:envoy/widgets/buttonWidget.dart';

import 'package:envoy/widgets/ordersCardFillEmptyWidget.dart';
import 'package:envoy/widgets/logoWidget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:envoy/settings/functions.dart';
import 'package:toast/toast.dart';

class HomePage extends StatefulWidget {
  final UserJsonModel userData;
  final OrderJsonModel orderData;
  const HomePage({Key key, this.userData, this.orderData}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState(userData: userData, orderData: orderData);
}

class _HomePageState extends State<HomePage> {
  UserJsonModel  userData;
  OrderJsonModel orderData;
  _HomePageState({this.userData, this.orderData});

  @override
  void initState() {
  super.initState();
    setState(() {    
   });
  }

  List<String> base64DocFill = [];
  // base64 images listesi (yükleme)

  List<String> base64DocEmpty = [];
  // base64 images listesi (boşaltma)

//--------------------Sipariş Listesi Yenileme Fonksiyonu-----------------------
  Future refreshList(int durumId, int companyId) async {
    final OrderJsonModel orderList = await orderJsonFunc(durumId,companyId); 
    setState(() {
      orderData = orderList;
    });
  }
//------------------------------------------------------------------------------

//--------------------seçilen resmi yükleme fonksiyonu--------------------------
  Future uploadSelectedImage(ImageSource source,List<String> base) async {
    final imagePicker = ImagePicker();
    final selected    = await imagePicker.getImage(source: source);
   
      if (selected != null) {
          selectedImage = File(selected.path);  
          base.add(imageToBase64(selectedImage));
          //çekilen resim base64 e dönüştürülüp, listeye eklendi
      }  
  }
//------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //--------------------------Appbar Stili--------------------------------
        appBar: AppBar(
        title: Text("siparişler", style: leadingStyle),
        actions: [
          IconButton(icon: Icon(Icons.exit_to_app),onPressed: (){
                
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
          })
        ],
        ),
        //----------------------------------------------------------------------
          body : Container(
          color: bgColor, // arkaplan rengi
          child: Column(
            children: [
              SizedBox(height: maxSpace),
              Flexible(child : RefreshIndicator(
                onRefresh: ()=> refreshList(globalDurumId, userData.user.id), // yukarıdan aşağı kaydırılınca listeyi yenileme
                child: ListView.builder(
                    itemCount  : orderData.siparisList.length,
                    itemBuilder: (BuildContext context, int index){
                      if(orderData.siparisList.length == 0 && orderData.siparisList == null){
                        return CircularProgressIndicator();
                      }
                      else
                      //------------------------------Sipaişler Card İçeriği---------------------------------------
                      return OrdersCardFillEmptyWidget(
                        deliveryDate   : orderData.siparisList[index].teslimTarihi,
                        fillingPoint   : orderData.siparisList[index].dolumyeri,
                        deliveryStation: orderData.siparisList[index].teslimatIstasyonu,
                        totalLT        : orderData.siparisList[index].toplamLitre,
                        status         : orderData.siparisList[index].durumId == 1 ? "Yeni Sipariş" : "Onaylandı" ,
                        statusColor    : orderData.siparisList[index].durumId == 1 ? Colors.white : checkedTxtColor,
                      //--------------------------------------------------------------------------------------------
                      //---------------SLİADABLE ON TAP'İ-------------------------
                        onTap: () async {
                          setState(() {
                              globalOrderId = orderData.siparisList[index].id;
                          });                        
                          final orderDetailData = await orderDetailJsonFunc(globalOrderId);
                          Navigator.push(context, 
                          MaterialPageRoute(builder: (context) => OrderDetailPage(orderDetailData: orderDetailData,base64DocEmpty: base64DocEmpty,base64DocFill: base64DocFill,userData: userData)));
                        },                       
                      //-------------------------------------------------------------------------
                      // Sipariş onaylanmamışsa onayla butonu olan görünüm gelecek
                      // durumId = 1 ise onayla görünümü gelecek tıklandığında durum id = 2 olacak
                        child: (orderData.siparisList[index].durumId == 1) 
                            ?  ButtonWidget(
                                buttonText : "onayla",
                                buttonWidth: deviceWidth(context),
                                buttonColor: btnColor,
                                onPressed  : () async{  // belge ve belge id'si gönderilmiyor, yalnızca durumId güncelleniyor                                                                                              
                                    await documentJsnAddFunc(orderData.siparisList[index].id, userData.user.id, 2, 0,null); // belgeId = null, belgeiçerik = null
                                    await refreshList(globalOrderId,userData.user.id); // listeyi güncelleme                                                                                                                              
                                })

                                : // sipariş onaylanmışsa doldur - boşalt butonları olan görünüm gelecek
                                  // durumId 1 değilse 2 veya 3 ise oluşacak durumlar
                                Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  //--------------------------------------DOLDUR BUTONU-----------------------------------
                                  // durumId = 2 ise liste boş değilse(fotoğraf çekilmişse) durumId = 3 olarak güncellenecek, 
                                  // doldur butonu pasifleştirilecek ve fotoğraf servise gönderilecek
                                  ButtonWidget(
                                    buttonText : "doldur",
                                    buttonWidth: deviceWidth(context) * 0.46, // buton genişliği
                                    buttonColor: btnColor,
                                    onPressed  : orderData.siparisList[index].durumId == 2 ?
                                    () async{
                                        await uploadSelectedImage(ImageSource.camera, base64DocFill); // kameradan fotoğraf çekip base64DocFill listesine ekleme
                                        if(base64DocFill.isNotEmpty)
                                        {
                                        showMessage(context, base64DocFill,3,orderData.siparisList[index].id);} // fotoğrafı değişen durumlarıyla servise gönderme, alertDialog gösterme
                                        await refreshList(globalOrderId,userData.user.id); // listeyi güncelleme                                       
                                        //show message
                                        
                                    } 
                                    :  (){} // durumId 2'den farklı olduğunda doldur butonunu pasifleştirme
                                  ),
                                  //----------------------------------------------------------------------------------------
                                  //-------------------------------------BOŞALT BUTONU---------------------------------------
                                  // durumId = 3 ise liste boş değilse(fotoğraf çekilmişse) durumId = 4 olarak güncellenecek, 
                                  // boşalt butonu pasifleştirilecek ve fotoğraf servise gönderilecek
                                  ButtonWidget(
                                    buttonText : "boşalt",
                                    buttonWidth: deviceWidth(context) * 0.46, // buton genişliği
                                    buttonColor: checkDateColor,
                                    onPressed  : orderData.siparisList[index].durumId == 3 ? 
                                    () async{
                                        await uploadSelectedImage(ImageSource.camera, base64DocEmpty); // kameradan fotoğraf çekip base64DocEmpty listesine ekleme
                                        if(base64DocEmpty.isNotEmpty)
                                        {
                                        showMessage(context, base64DocEmpty,4,orderData.siparisList[index].id);} // fotoğrafı değişen durumlarıyla servise gönderme, alertDialog gösterme
                                        await refreshList(globalOrderId, userData.user.id); // listeyi güncelleme   
                                        //show message
                                        
                                    } 
                                    : (){} // durumId 3'ten farklı olduğunda doldur butonunu pasifleştirme
                                  ),
                                  //-------------------------------------------------------------------------------------------
                                ],
                         )
                      );
                    },
                  ),
               ),
             ),
            ],
          ),
        ),
        bottomNavigationBar: LogoWidget()); // en alttaki logo görünümü
  }

  showMessage(BuildContext context, List<String> document,int stateID, int orderID) { 
  return showDialog(context: context, builder: (BuildContext context){
    return AlertDialog(
      content: Text("Tekrar belge fotoğrafı çekmek ister misiniz ?",style: TextStyle(fontFamily: contentFont)),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [   
          //-----------------------------------EVET BUTONU-----------------------------------------     
          MaterialButton(
            color: btnColor,
            child: Text("Evet",style: TextStyle(fontFamily: leadingFont)), // fotoğraf çekilmeye devam edilecek
            onPressed: () async{
            await uploadSelectedImage(ImageSource.camera, document);
            }),
          //---------------------------------------------------------------------------------------
          SizedBox(width: maxSpace), // iki buton arası boşluk
          //-----------------------------------HAYIR BUTONU----------------------------------------
          MaterialButton( 
            color    : btnColor,
            child    : Text("Hayır",style: TextStyle(fontFamily: leadingFont)),
            onPressed: () async{                                    
              for (var i = 0; i <= document.length -1; i++){            
              await documentJsnAddFunc(orderID, userData.user.id, stateID, 0,document[i]);}

              // Toast message çekilen döküman sayısını gösterecek  
              Toast.show("${document.length} belge kaydedildi !", context, backgroundColor: Colors.grey,duration: 3, textColor: Colors.black);
              refreshList(globalOrderId,userData.user.id);              
              Navigator.of(context).pop();
              document.clear();
            }),
          //---------------------------------------------------------------------------------------
        ]),        
      ],
    );
  });    
}
}


