// -----------------------------------------
// Publish and Dashboard with Laundry Alert
// -----------------------------------------
// This app will publish an event when the Laundry is finished.
// It will publish a different event when .

// Just like before, we're going to start by declaring which pins everything is plugged into.

int led = D0; // This is where your LED is plugged in. The other side goes to a resistor connected to GND.
int boardLed = D7; // This is the LED that is already on your device.
// On the Core, it's the LED in the upper right hand corner.
// On the Photon, it's next to the D7 pin.

int doorSensor = D1;  // This is where your magnetic door switch is plugged in. The other side goes to the "powerDoor" pin (below).
int knockSensor = A0;  // This is where your vibration sensor is plugged in. The other side goes to the "powerKnock" pin (below).
int soundSensor = A; // This is where your sound sensor is plugged in. The other side goes to the "powerSound" pin (below).

int powerDoor = A4; // This is the other end of your photoresistor. The other side is plugged into the "doorSensor" pin (above).
int powerKnock = A5; // This is the other end of your photoresistor. The other side is plugged into the "knockSensor" pin (above).
int powerSound = A6; // This is the other end of your photoresistor. The other side is plugged into the "soundSensor" pin (above).


// The following values get set up when your device boots up and calibrates:
int intactValue; // This is the average value that the photoresistor reads when the beam is intact.
int brokenValue; // This is the average value that the photoresistor reads when the beam is broken.

int soundValue = 0;  // This is the value that the sound sensor reads.

int knockThreshold = 100; // This is a value halfway between ledOnValue and ledOffValue, above which we will assume the led is on and below which we will assume it is off.
int soundThreshold = 100; // This is a value halfway between ledOnValue and ledOffValue, above which we will assume the led is on and below which we will assume it is off.

bool beamBroken = false; // This flag will be used to mark if we have a new status or now. We will use it in the loop.

// We start with the setup function.

void setup() {
  // This part is mostly the same:
  pinMode(led,OUTPUT); // Our LED pin is output (lighting up the LED)
  pinMode(boardLed,OUTPUT); // Our on-board LED is output as well
  pinMode(photoresistor,INPUT);  // Our photoresistor pin is input (reading the photoresistor)
  
  pinMode(powerDoor,OUTPUT); // The pin powering the photoresistor is output (sending out consistent power)
  pinMode(powerKnock,OUTPUT); // The pin powering the photoresistor is output (sending out consistent power)
  pinMode(powerSound,OUTPUT); // The pin powering the photoresistor is output (sending out consistent power)


  // Next, write the power of the photoresistor to be the maximum possible, which is 4095 in analog.
  digitalWrite(power,HIGH);

  // Since everyone sets up their leds differently, we are also going to start by calibrating our photoresistor.
  // This one is going to require some input from the user!

  // First, the D7 LED will go on to tell you to put your hand in front of the beam.
  digitalWrite(boardLed,HIGH);
  delay(2000);

  // Then, the D7 LED will go off and the LED will turn on.
  digitalWrite(boardLed,LOW);
  digitalWrite(led,HIGH);
  delay(500);

  // Now we'll take some readings...
  int on_1 = analogRead(photoresistor); // read photoresistor
  delay(200); // wait 200 milliseconds
  int on_2 = analogRead(photoresistor); // read photoresistor
  delay(300); // wait 300 milliseconds

  // Now flash to let us know that you've taken the readings...
  digitalWrite(boardLed,HIGH);
  delay(100);
  digitalWrite(boardLed,LOW);
  delay(100);
  digitalWrite(boardLed,HIGH);
  delay(100);
  digitalWrite(boardLed,LOW);
  delay(100);

  // Now the D7 LED will go on to tell you to remove your hand...
  digitalWrite(boardLed,HIGH);
  delay(2000);

  // The D7 LED will turn off...
  digitalWrite(boardLed,LOW);

  // ...And we will take two more readings.
  int off_1 = analogRead(photoresistor); // read photoresistor
  delay(200); // wait 200 milliseconds
  int off_2 = analogRead(photoresistor); // read photoresistor
  delay(1000); // wait 1 second

  // Now flash the D7 LED on and off three times to let us know that we're ready to go!
  digitalWrite(boardLed,HIGH);
  delay(100);
  digitalWrite(boardLed,LOW);
  delay(100);
  digitalWrite(boardLed,HIGH);
  delay(100);
  digitalWrite(boardLed,LOW);
  delay(100);
  digitalWrite(boardLed,HIGH);
  delay(100);
  digitalWrite(boardLed,LOW);


  // Now we average the "on" and "off" values to get an idea of what the resistance will be when the LED is on and off
  intactValue = (on_1+on_2)/2;
  brokenValue = (off_1+off_2)/2;

  // Let's also calculate the value between ledOn and ledOff, above which we will assume the led is on and below which we assume the led is off.
  beamThreshold = (intactValue+brokenValue)/2;

}


// Now for the loop.

void loop() {
  /* In this loop function, we're going to check to see if the beam has been broken.
  When the status of the beam changes, we'll send a Spark.publish() to the cloud
  so that if we want to, we can check from other devices when the LED is on or off.

  We'll also turn the D7 LED on when the Photoresistor detects a beam breakagse.
  */
  
  /************************************************************
   Check for door status
   ************************************************************/
   
  doorStatus = digitalRead(door);
  
  if(doorStatus == HIGH) {
    doorClosed = true;
    digitalWrite(boardLed, HIGH);
    delay(300000);  // wait for 5 minutes
  }
  else {
    digitalWrite(boardLed, LOW);
  }



  /* Check for vibration of the washer.
     Only check for vibration if the washer door is closed. */
  if(doorClosed) {

    // It will set laundering true if it detects vibration.
    vibrationCheck();
    
    // In case it did not detect the vibration of the washer at first place then it will check it again after 10 minutes.
    if(!laundering) {
      delay(600000);
      vibrationCheck();
    }
    
    // If the door is closed by accident or there is sensor error when washer is not running, send a txt message.
    if(!laundering) {
      doorClosed = false;
      //send itfff alert saying wahser is off & door is closed
      // 10digitnumner@tmomail.net
      }
  }
  
  /* Now, we know that washer is running. 
     We are going to check the washer status using vibration sensor & sound sensor.
  while(doorClosed) {
    
    soundValue = analogRead(knockSensor);
    
    if (soundValue >= threshold) {
     // toggle the status of the ledPin:
     ledState = !ledState;
     // update the LED pin itself:
     digitalWrite(ledPin, ledState);
     
     vibrationCheck();
     launderyFinish = true;
   }
   
   // We'll leave it on for 1 second...
   delay(1000); 
  }  
    
  
  while(launderyFinish) {
    // send ifttt sms message that whaser is finished
    
    // Check for door status
    doorStatus = digitalRead(door);
  
    // if door is open, then stop send sms message
    if(doorStatus == LOW) {
      break;
    }
    
    delay(1800000); send message every 30 minutes
  }

  

  if (analogRead(photoresistor)>beamThreshold) {

    /* If you are above the threshold, we'll assume the beam is intact.
    If the beam was intact before, though, we don't need to change anything.
    We'll use the beamBroken flag to help us find this out.
    This flag monitors the current status of the beam.
    After the beam is broken, it is set TRUE
    and when the beam reconnects it is set to FALSE.
    */

    if (beamBroken==true) {
        // If the beam was broken before, then this is a new status.
        // We will send a publish to the cloud and turn the LED on.

        // Send a publish to your devices...
        Spark.publish("beamStatus","intact",60,PRIVATE);
        // And flash the on-board LED on and off.
        digitalWrite(boardLed,HIGH);
        delay(500);
        digitalWrite(boardLed,LOW);

        // Finally, set the flag to reflect the current status of the beam.
        beamBroken=false;
    }
    else {
        // Otherwise, this isn't a new status, and we don't have to do anything.
    }
  }

  else {
      // If you are below the threshold, the beam is probably broken.
      if (beamBroken==false) {

        // Send a publish...
        Spark.publish("beamStatus","broken",60,PRIVATE);
        // And flash the on-board LED on and off.
        digitalWrite(boardLed,HIGH);
        delay(500);
        digitalWrite(boardLed,LOW);

        // Finally, set the flag to reflect the current status of the beam.
        beamBroken=true;
      }
      else {
          // Otherwise, this isn't a new status, and we don't have to do anything.
      }
  }

}


bool vibrationCheck() {
  if (analogRead(vibration) > vibThreshold) {
    laundering = true;
  }
  else {
    laudering = false;
  }
}
