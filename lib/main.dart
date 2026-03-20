import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main()=>runApp(const MaterialApp(debugShowCheckedModeBanner:false,home:App()));

class Medal{final String name;final int steps;const Medal(this.name,this.steps);}

class App extends StatefulWidget{
  const App({super.key});
  @override State<App> createState()=>_AppState();
}

class _AppState extends State<App> with TickerProviderStateMixin{
  static const sensor=MethodChannel("movego_channel");

  int page=0,steps=0,days=5;
  DateTime date=DateTime.now();

  final history=<String,int>{};
  final unlocked=<String,bool>{};

  late AnimationController stepCtrl;
  late Animation<double> stepAnim;

  final medals=const[
    Medal("初試啼聲",1),
    Medal("500步",500),
    Medal("1000步",1000),
    Medal("5000步",5000),
    Medal("10000步",10000)
  ];

  String key(DateTime d)=>"${d.year}-${d.month}-${d.day}";
  double get km=>steps*0.0007;
  double get kcal=>steps*0.04;

  @override
  void initState(){
    super.initState();
    stepCtrl=AnimationController(vsync:this,duration:const Duration(milliseconds:400));
    stepAnim=Tween<double>(begin:0,end:0).animate(stepCtrl);

    sensor.setMethodCallHandler((call)async{
      if(call.method=="step")add(1);
    });
  }

  @override
  void dispose(){stepCtrl.dispose();super.dispose();}

  void add(int n){
    setState(()=>steps+=n);
    history[key(date)]=steps;

    stepAnim=Tween<double>(begin:0,end:steps.toDouble())
        .animate(CurvedAnimation(parent:stepCtrl,curve:Curves.easeOut));

    stepCtrl.forward(from:0);

    for(var m in medals){
      if(unlocked[m.name]==true)continue;
      if(steps>=m.steps){
        unlocked[m.name]=true;
        showDialog(context:context,builder:(_)=>MedalPopup(m.name));
        break;
      }
    }
  }

  Widget btn(String t,VoidCallback f)=>ElevatedButton(onPressed:f,child:Text(t));

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body:Container(
        decoration:const BoxDecoration(
            gradient:LinearGradient(
                colors:[Colors.black,Colors.black54],
                begin:Alignment.topCenter,end:Alignment.bottomCenter)),
        child:[stepPage(),chartPage(),medalPage()][page],
      ),
      bottomNavigationBar:BottomNavigationBar(
        currentIndex:page,
        onTap:(i)=>setState(()=>page=i),
        items:const[
          BottomNavigationBarItem(icon:Icon(Icons.directions_run),label:"計步"),
          BottomNavigationBarItem(icon:Icon(Icons.bar_chart),label:"統計"),
          BottomNavigationBarItem(icon:Icon(Icons.emoji_events),label:"勳章")
        ],
      ),
    );
  }

  Widget stepPage()=>Center(
    child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Text("${date.month}/${date.day}",style:const TextStyle(color:Colors.white)),
      const Text("今日步數",style:TextStyle(color:Colors.white)),

      AnimatedBuilder(
          animation:stepCtrl,
          builder:(_,__)=>Text(
            "${stepCtrl.isAnimating?stepAnim.value.toInt():steps}",
            style:const TextStyle(fontSize:70,fontWeight:FontWeight.bold,color:Colors.cyanAccent),
          )),

      Text("距離 ${km.toStringAsFixed(2)} km",style:const TextStyle(color:Colors.white70)),
      Text("熱量 ${kcal.toStringAsFixed(1)} kcal",style:const TextStyle(color:Colors.white70)),

      const SizedBox(height:20),

      btn("增加100步",()=>add(100)),

      btn("下一天",(){
        setState((){
          history[key(date)]=steps;
          date=date.add(const Duration(days:1));
          steps=0;
        });
      }),

      btn("重置",(){
        setState((){
          steps=0;
          history.clear();
          unlocked.clear();
          date = DateTime.now();
        });
      })
    ]),
  );

  Widget chartPage()=>Column(children:[
    const SizedBox(height:50),
    const Text("趨勢圖",style:TextStyle(fontSize:24,color:Colors.white)),

    Row(mainAxisAlignment:MainAxisAlignment.center, children:[5,10,15].map((d)=>Padding(
      padding:const EdgeInsets.all(6),
      child:ChoiceChip(label:Text("$d天"),
          selected:days==d,
          onSelected:(_)=>setState(()=>days=d
          )),
    )).toList()),

    SizedBox(height:200,child:Chart(history,date,days)),

    Expanded(child:ListView.builder(
        itemCount:days,
        itemBuilder:(_,i){
          DateTime d=date.subtract(Duration(days:i));
          int s=history[key(d)]??0;
          return ListTile(
              title:Text("${d.month}/${d.day}",style:const TextStyle(color:Colors.white)),
              trailing:Text("$s 步",style:const TextStyle(color:Colors.cyanAccent)));
        }))
  ]);

  Widget medalPage()=>Center(
    child:GridView.count(
        crossAxisCount:2,
        shrinkWrap:true,
        padding:const EdgeInsets.all(20),
        crossAxisSpacing:20,
        mainAxisSpacing:20,
        children:medals.map((m){
          bool ok=unlocked[m.name]==true;
          return Card(
              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20)),
              color:ok?Colors.amber:Colors.grey.shade700,
              child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                ok?const SpinGlowMedal():const Icon(Icons.lock,size:50,color:Colors.white54),
                const SizedBox(height:10),
                Text(m.name,style:const TextStyle(color:Colors.white))
              ]));
        }).toList()),
  );
}

class SpinGlowMedal extends StatefulWidget{
  const SpinGlowMedal({super.key});
  @override State<SpinGlowMedal> createState()=>_SpinGlowMedal();
}

class _SpinGlowMedal extends State<SpinGlowMedal> with SingleTickerProviderStateMixin{
  late AnimationController spin;

  @override
  void initState(){
    super.initState();
    spin=AnimationController(vsync:this,duration:const Duration(seconds:3))..repeat();
  }

  @override
  void dispose(){spin.dispose();super.dispose();}

  @override
  Widget build(BuildContext context)=>AnimatedBuilder(
    animation: spin,
    builder: (_,__)=>Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
              angle: spin.value * 6.28,
              child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(colors: [Colors.transparent, Colors.amber, Colors.transparent],),
                      boxShadow: [BoxShadow(color: Colors.amber.withOpacity(.8), blurRadius: 30, spreadRadius: 6)]
                  )
              )
          ),
          const Icon(Icons.emoji_events, size: 50, color: Colors.white54)
        ]
    ),
  );
}

class Chart extends StatefulWidget{
  final Map<String,int> history;
  final DateTime date;
  final int days;
  const Chart(this.history,this.date,this.days,{super.key});
  @override State<Chart> createState()=>_ChartState();
}

class _ChartState extends State<Chart> with SingleTickerProviderStateMixin{
  late AnimationController anim;

  @override
  void initState(){
    super.initState();
    anim=AnimationController(vsync:this,duration:const Duration(milliseconds:900))..forward();
  }

  @override
  void didUpdateWidget(covariant Chart oldWidget){
    super.didUpdateWidget(oldWidget);
    if(oldWidget.days!=widget.days)anim.forward(from:0);
  }

  @override
  Widget build(BuildContext context){
    const maxHeight=120;
    List<int> values=List.generate(widget.days,(i){
      DateTime d=widget.date.subtract(Duration(days:widget.days-1-i));
      return widget.history["${d.year}-${d.month}-${d.day}"]??0;
    });

    int max=values.reduce((a,b)=>a>b?a:b);
    if(max==0)max=1;

    return AnimatedBuilder(
        animation:anim,
        builder:(_,__)=>Row(
          crossAxisAlignment:CrossAxisAlignment.end,
          mainAxisAlignment:MainAxisAlignment.spaceEvenly,
          children:List.generate(values.length,(i){
            double h=(values[i]/max)*maxHeight*anim.value;
            if(h<4)h=4;

            DateTime d=widget.date.subtract(Duration(days:widget.days-1-i));

            return Column(mainAxisAlignment:MainAxisAlignment.end,children:[
              if(values[i]>0)
                Text("${values[i]}",style:const TextStyle(fontSize:10,color:Colors.cyanAccent)),

              Container(
                  width:widget.days==5?26:18,
                  height:h,
                  decoration:BoxDecoration(
                      gradient:LinearGradient(
                          colors:values[i]==0
                              ?[Colors.white24,Colors.white10]
                              :[Colors.cyanAccent,Colors.blueAccent]),
                      borderRadius:BorderRadius.circular(8),
                      boxShadow:values[i]==0?[]:[
                        BoxShadow(color:Colors.cyanAccent.withOpacity(.7),blurRadius:20,spreadRadius:2)
                      ])),

              const SizedBox(height:4),
              Text("${d.day}",style:const TextStyle(color:Colors.white70))
            ]);
          }),
        ));
  }
}

class MedalPopup extends StatelessWidget{
  final String name;
  const MedalPopup(this.name,{super.key});

  @override
  Widget build(BuildContext context)=>Dialog(
    backgroundColor:Colors.transparent,
    child:Column(mainAxisSize:MainAxisSize.min,children:[
      Container(
        decoration:BoxDecoration(shape:BoxShape.circle,boxShadow:[
          BoxShadow(color:Colors.amber.withOpacity(.9),blurRadius:40,spreadRadius:8)
        ]),
        child:SpinGlowMedal(),
      ),
      const SizedBox(height:20),
      Text(name,style:const TextStyle(fontSize:22,color:Colors.white))
    ]),
  );
}
