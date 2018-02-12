import de.voidplus.myo.*;
import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress dest;
Myo myo;
ArrayList<ArrayList<Integer>> sensors;

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
  


void draw() {
  background(255);
  // ...
  
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
     msg.add(data[i]);
   }
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
