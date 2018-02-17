import de.voidplus.myo.*;
import oscP5.*;
import netP5.*;

int id=0;
OscP5 oscP5;
NetAddress dest;
Myo myo;
ArrayList<ArrayList<Integer>> sensors;

PFont f;
PImage img;

float[][] SmoothArray = { {0,0,0,0,0,0,0,0}, {0,0,0,0,0,0,0,0}, {0,0,0,0,0,0,0,0}, {0,0,0,0,0,0,0,0}, {0,0,0,0,0,0,0,0}};   

void setup() {
  size(800, 400);
  background(255);
  noFill();
  stroke(0);
  // ...

  myo = new Myo(this, true); // true, with EMG data
  
  sensors = new ArrayList<ArrayList<Integer>>();
  for (int i=0; i<8; i++) {
    sensors.add(new ArrayList<Integer>()); 
  }
    oscP5 = new OscP5(this,12000);
  dest = new NetAddress("127.0.0.1",6448);
  frameRate(90);
}

//this function moves the values down by one each iteration of the array
void writeback(int j){
    SmoothArray[0][j] = 0;
    for(int i=4; i>0; i--){
      float temp = SmoothArray[i][j];
      SmoothArray[i-1][j] = temp;
    } 
}

//averages the rows
int average(int j){
  int sum = 0;
  for(int i=0;i<4;i++){
    sum += SmoothArray[i][j];
  }
  return round(sum/5);

}


void draw() {
  background(255);
  // ...
  if(id == 1){
  background(0);
   img = loadImage("dyel.jpg");
  image(img,0,0);
  }
  if(id == 2){
  img = loadImage("mebro.jpg");
  image(img,0,0);
  }
  if(id == 3){
  img = loadImage("billplates.png");
  image(img,0,0);
  }
  // Drawing:
  synchronized (this) {
    for (int i=0; i<8; i++) {
      if (!sensors.get(i).isEmpty()) {
        beginShape();
        for (int j=0; j<sensors.get(i).size(); j++) {
          vertex(j, sensors.get(i).get(j)+(i*50));
        }
        endShape();
      } 
    }
  }
  
}

// ----------------------------------------------------------


void sendOsc(int data[]) {
  OscMessage msg = new OscMessage("/wek/inputs");
  msg.add((int)data[1]); 
  msg.add((int)data[2]);
  msg.add((int)data[3]);
  msg.add((int)data[4]);
  msg.add((int)data[5]);
  msg.add((int)data[6]);
  msg.add((int)data[7]);
  msg.add((int)data[8]);
  oscP5.send(msg, dest);
}

void myoOnEmgData(Device myo, long timestamp, int[] data) {
  // println("Sketch: myoOnEmgData, device: " + myo.getId());
  // int[] data <- 8 values from -128 to 127
   OscMessage msg = new OscMessage("/wek/inputs");
   for (int i = 0; i<data.length; i++){
     writeback(i);
     SmoothArray[0][i] = abs(data[i]);
     float avg = average(i);
     msg.add((float)avg);
     
     //print("  i is",i);  
     //print("  message is",avg);
 
   }
   //println();
     oscP5.send(msg, dest);
     
     synchronized (this) {
    for (int i = 0; i<data.length; i++) {
      sensors.get(i).add((int) map(data[i], -128, 127, 0, 50)); // [-128 - 127]
     
    }
    while (sensors.get(0).size() > width) {
      for(ArrayList<Integer> sensor : sensors) {
        sensor.remove(0);
      }
    }
  }
}

void oscEvent(OscMessage theOscMessage) {
 if (theOscMessage.checkAddrPattern("/wek/outputs")==true) {
     if(theOscMessage.checkTypetag("fff")) { // looking for 3 parameters
        float noclick = theOscMessage.get(0).floatValue();
        float clickL = theOscMessage.get(1).floatValue();
        float clickR = theOscMessage.get(2).floatValue();
        //println("Received new output values from Wekinator");  
        print("message recieved from Wekinator:", noclick,clickL,clickR);
        float temp = Math.max(Math.max(noclick,clickL),Math.max(clickL,clickR));
        if (temp == noclick){
          id = 1;
          redraw();
        }
        if (temp == clickL){
          id=2;
           redraw();
        }
        if (temp == clickR){
          id=3;
          redraw();
        }

      } else {
        println("Error: unexpected OSC message received by Processing: ");
        theOscMessage.print();
      }

 }
}