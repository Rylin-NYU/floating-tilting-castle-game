import processing.serial.*;
import processing.sound.*;

Serial serialPort;

int NUM_OF_VALUES_FROM_ARDUINO = 3;  /* CHANGE THIS ACCORDING TO YOUR PROJECT */
/* This array stores values from Arduino */
int arduino_values[] = new int[NUM_OF_VALUES_FROM_ARDUINO];

int NUM_OF_VALUES_FROM_PROCESSING = 3;  /* CHANGE THIS ACCORDING TO YOUR PROJECT */
/* This array stores values you might want to send to Arduino */
int processing_values[] = new int[NUM_OF_VALUES_FROM_PROCESSING];

//ball physics
float x, y; // ball position
float radius = 25; // ball radius
float velocity_x = 0;
float velocity_y = 0;
float friction = .99;
float scale_x = .6;
float scale_y = .6;

boolean unchosen = true; //checks whether player has selected a difficulty
boolean chosenEndless = false;
boolean chosenChaos = false;
boolean chosenTutorial = false; //difficulty check
boolean gameOver = false;
int gameMode = 0;

//reset button 
int buttonState = 0;
int lastButtonState = 0;
//wave graphic info
int numWaves = 20; 
float[] waveX = new float[numWaves];
float[] waveY = new float[numWaves];
//timer
int startTime = 0;
boolean timerStarted = false;
float finalTime = 0;  
  
//wind physics influenced from BOX2D libraty
float windX = 0;
float windY = 0;
int lastWindChange = 0;
int windInterval = 3000; // change every 2 seconds
float windOffsetX = 0;
float windOffsetY = 0;
float windSpeed = 10; // 

//Crevices 
float creviceX, creviceY;
boolean creviceActive = false;
int points = 0;
//Crevice timer (for Chaos mode)
int creviceStarTtime = 0;
int creviceTimeLimit = 15000; // 15 seconds
float puddleRadius = 30;

//audio 
SoundFile sound;
int lastGameMode = -1;


void setup() {
  size(1000, 1000);  
  smooth();
  background(0);
  x = width/2;
  y = height/2;
  printArray(Serial.list());
  // put the name of the serial port your Arduino is connected
  // to in the line below - this should be the same as you're
  // using in the "Port" menu in the Arduino IDE
  serialPort = new Serial(this, "COM4", 115200  );
}

void draw() {
  getSerialData();
  
  //menu system for management and for Arduino lighting and audio
  if (unchosen) {
    gameMode = 0;
  }
  else if (gameOver) {
  gameMode = 4;
  }
  else if (chosenTutorial) {
    gameMode = 1;
  }    
  else if (chosenEndless) {
    gameMode = 2;
  }
  else if (chosenChaos) {
    gameMode = 3;
  }
  processing_values[2] = gameMode;
  
  // MENU SCREEN
  if (gameMode == 0 && lastGameMode != 0) {
    if (sound != null) {
      sound.stop();
    }
    sound = new SoundFile(this, "Lopkerjo - Lotus Quiet.mp3");
    sound.loop();
    lastGameMode = 0;
  }
  
  // TUTORIAL SCREEN
  if (gameMode == 1 && lastGameMode != 1) {
    if (sound != null) {
      sound.stop();
    }
    sound = new SoundFile(this, "Eggy Toast - 7.mp3.mp3");
    sound.loop();
    lastGameMode = 1;
  }
  
  // EASY SCREEN
  if (gameMode == 2 && lastGameMode != 2) {
    if (sound != null) {
      sound.stop();
    }
    sound = new SoundFile(this, "Jean-Michel - Main Theme.mp3");
    sound.loop();
    lastGameMode = 2;
  }
  
  // CHAOS SCREEN
  if (gameMode == 3 && lastGameMode != 3) {
    if (sound != null) {
      sound.stop();
    }
    sound = new SoundFile(this, "Kirk Osamayo - Chaos.mp3");
    sound.loop();
    lastGameMode = 3;
  }
  
  // GAME OVER SCREEN
  if (gameMode == 4 && lastGameMode != 4) {
    if (sound != null) {
      sound.stop();
    }
    sound = new SoundFile(this, "Lite Saturation - Sad.mp3");
    sound.loop();
    lastGameMode = 4;
  }
  
  background(#98ACF7);
  stroke(0);
  
  //selection screen sequence
  if (unchosen){startScreen();}
  
  
  //reset game---------------------------------------------
   buttonState = arduino_values[2];
   if (buttonState == 1 && lastButtonState == 0) {
    resetGame();
  }
  
  
  lastButtonState = buttonState;
  //-------------------------------------------------------
  
  if (gameOver) {
    gameOver();
    return;  
  }
  //endless game mode
  if(chosenEndless){
    endlessGameMode();
  }
  //Chaos game mode
  if(chosenChaos){
    chaosGameMode();
  }
  //tutorial game mode
  if(chosenTutorial){
    tutorialGameMode();
  }
  
  
  
  // BALL PHYSICS ---------------------------------------
  // receive the values from Arduino
  float tiltX = arduino_values[0]; 
  float tiltY = arduino_values[1];


  // convert tilt → acceleration
  float accel_x = map(tiltX, -180, 180, -1, 1);
  float accel_y = map(tiltY, -180, 180, 1, -1);
  
  // update velocity
  velocity_x += accel_x * scale_x;
  velocity_y += accel_y * scale_y;
  
  // applying wind 
  if (!unchosen) {
    velocity_x += windX;
    velocity_y += windY;
  }
  
  // apply friction
  velocity_x *= friction;
  velocity_y *= friction;
  
  x += velocity_x;
  y += velocity_y;
  
  if (unchosen) {
    if (x < radius) {
      x = radius;
      velocity_x *= -1;
    }
    if (x > width - radius) {
      x = width - radius;
      velocity_x *= -1;
    }
    if (y < radius) {
      y = radius;
      velocity_y *= -1;
    }
    if (y > height - radius) {
      y = height - radius;
      velocity_y *= -1;
    }
  }
  
  fill(255);
  circle(x,y,50);
  
  // ------------------------------------------------------
  
  
  
  // TUTORIAL Mode Choice----------------------------------
  if(unchosen){
    if (x > 400 && x < 600 && y > 250 && y < 350) {
      startTime = millis();
      timerStarted = true;
    
      println("Tutorial selected");
    
      unchosen = false;
      chosenTutorial = true;
      creviceActive = true; 
      spawnCrevice();
    
      x = width/2;
      y = height/2;
      velocity_x = 0;
      velocity_y = 0;
    
      generateWaves();
    
      friction = 0.99;
      scale_x = 0.6;
      scale_y = 0.6;
    }
  }
  //-------------------------------------------------------
  // EASY Mode Choice--------------------------------------
  if (unchosen){
    if (x > 200 && x < 400 && y > 400 && y < 500) {
      startTime = millis();
      timerStarted = true;
      println("Endless selected");
      unchosen = false;
      chosenEndless = true;
      creviceActive = true;
      spawnCrevice();
      x = width/2;
      y = height/2;
      velocity_x = 0;
      velocity_y = 0;
      generateWaves();
      friction = 0.97;
      scale_x = 0.6;
      scale_y = 0.6;
    }
    if(chosenEndless){
      if (x < radius) {
        x = radius;
        velocity_x *= -1;
      }
      if (x > width - radius) {
        x = width - radius;
        velocity_x *= -1;
      }
      if (y < radius) {
        y = radius;
        velocity_y *= -1;
      }
      if (y > height - radius) {
        y = height - radius;
        velocity_y *= -1;
      }
    }
  }
  //display timer during endless game
  if (timerStarted && chosenEndless) {
    int elapsed = millis() - startTime;   // milliseconds since start
    float seconds = elapsed / 1000.0;
  
    fill(0);
    textSize(30);
    textAlign(CENTER);
    text("Ellapsed Time: " + seconds, 500, 150);
  }
  //------------------------------------------------------------------------
  
  // Chaos Mode Choice-------------------------------------------------------
  if (unchosen){
      if (x > 600 && x < 800 && y > 400 && y < 500) {
        startTime = millis();
        timerStarted = true;
        println("Chaos selected");
        unchosen = false;
        chosenChaos = true;
        creviceActive = true;
        creviceStarTtime = millis();
        spawnCrevice();
        x = width/2;
        y = height/2;
        velocity_x = 0;
        velocity_y = 0;
        generateWaves();
        friction = 0.99;
        scale_x = 0.6;
        scale_y = 0.6;
      }
  }
  //display timer during Chaos game
    if (chosenChaos) {
    float remaining = 15.0 - (millis() - creviceStarTtime) / 1000.0;
  
    if (remaining < 0) {
      remaining = 0;
      gameOver = true;
    }
  
    fill(0);
    textSize(30);
    textAlign(CENTER);
    text("Time Left: " + nf(remaining, 1, 2), 500, 150);
      
  }
  //------------------------------------------------------------------------
  
  //displaying wind direction for the player to see
  if (!unchosen && !chosenTutorial) {
    fill(255);
    textSize(40);
    textAlign(CENTER);
    text("Wind: " + nf(windX*10,1,1) + ", " + nf(windY*10,1,1), 500, 80);
    
    noFill();
    stroke(255);
    windOffsetX += windX * windSpeed;
    windOffsetY += windY * windSpeed;
    drawWind();
    // horizontal wrap
    if (windOffsetX > width + 200) {
      windOffsetX = -200;
    }
    if (windOffsetX < -200) {
      windOffsetX = width + 200;
    }
    
    if (windOffsetY > height + 200) {
      windOffsetY = -200;
    }
    if (windOffsetY < -200) {
      windOffsetY = height + 200;
    }
    
      
  }
  
  //Crevice spawning  + points scoring-----------------------------------------
  if (creviceActive) {
    stroke(0);
    strokeWeight(3);
    line(creviceX - 10, creviceY - 10, creviceX + 10, creviceY + 10);
    line(creviceX - 8, creviceY + 12, creviceX + 12, creviceY - 8);
    noStroke();
    fill(0, 150, 255, 120);
  
    for (int i = 0; i < 6; i++) {
      float offsetX = random(-10, 10);
      float offsetY = random(-10, 10);
      ellipse(creviceX + offsetX, creviceY + offsetY, puddleRadius, puddleRadius);
    }
    float d = dist(x, y, creviceX, creviceY);
  
    // collect Crevice
    if (d < radius + 10) {
      if (chosenChaos) {
        float remaining = 15.0 - (millis() - creviceStarTtime) / 1000.0;
        int lives = max(1, floor(remaining));  // whole seconds left, minimum 1
        points += lives;
        
        creviceStarTtime = millis(); // reset timer
      } else {
        points += 10;
      }
    spawnCrevice();
    }
  
    // Chaos mode timer
    if (chosenChaos) {
      if (millis() - creviceStarTtime > creviceTimeLimit) {
        gameOver = true;
      }
    }
  }
 //--------------------------------------------------------------------------
  
  
  // Endscreen when ball into the tower walls--------------------------------
  if (!gameOver && !unchosen) {

  boolean outsideMainWalls = (x < 100 || x > 900 || y < 100 || y > 900);

  boolean inTopLeftTower = (x > 50 && x < 250 && y > 50 && y < 250);
  boolean inTopRightTower = (x > 750 && x < 950 && y > 50 && y < 250);
  boolean inBottomLeftTower = (x > 50 && x < 250 && y > 750 && y < 950);
  boolean inBottomRightTower = (x > 750 && x < 950 && y > 750 && y < 950);

  boolean inAnyTower = inTopLeftTower || inTopRightTower || 
                       inBottomLeftTower || inBottomRightTower;

  if (outsideMainWalls && !inAnyTower) {
    gameOver = true;
    finalTime = (millis() - startTime) / 1000.0;
  }
}
  //------------------------------------------------------------------------
  
  
  // point display
  if (!unchosen) {
    textSize(30);
    textAlign(RIGHT);
    fill(255);
    if (chosenChaos){
    text("Lives Saved: " + points, 900, 180);
    }
    if(chosenEndless){
    text("Survival Score: " + points, 900, 180);
    }
  }

}

//start screen code
void startScreen(){

  // subtle animated background tint
  background(#98ACF7);

  
  float bob = sin(frameCount * 0.02) * 6;

  textAlign(CENTER);
  textSize(60);
  fill(255);
  text("The Floating Castle", 500, 140 + bob);
  
  //shadows
  fill(0, 60);
  rect(205, 405, 200, 100, 20);
  rect(605, 405, 200, 100, 20);
  rect(405, 255, 200, 100, 20);

  textSize(20);
  fill(220);
  text("Tilt to Move • Avoid Sinking • Save Lives", 500, 180 + bob);
  fill(#6BB702);
  rect(200, 400, 200, 100, 20);
  fill(0);
  textSize(40);
  text("Easy", 300, 465);
  
  // CHAOS BUTTON
  fill(#FC0A53);
  rect(600, 400, 200, 100, 20);
  fill(0);
  text("Chaos", 700, 465);
  
  // TUTORIAL BUTTON
  fill(#A974FF);
  rect(400, 250, 200, 100, 20);
  fill(#FFEA74);
  textSize(30);
  text("Tutorial", 500, 315);

  
  fill(255);
  textSize(22);
  text("Move the ball onto a mode to start", 500, 700);

  textSize(18);
  fill(200);
  text("Easy = Endless survival • Chaos = Timed challenge", 500, 740);
}

void tutorialGameMode(){
  background(#1A48E8);

  // Main castle body
  fill(#B4B4B4);
  stroke(#906C3D);
  strokeWeight(2);
  rect(100, 100, 800, 800);

  // Corner towers with battlements
  drawTower(50, 50);    // top left
  drawTower(750, 50);   // top right
  drawTower(50, 750);   // bottom left
  drawTower(750, 750);  // bottom right

  // Main wall battlements
  drawTopWall();
  drawBottomWall();
  drawLeftWall();
  drawRightWall();
  
  noStroke();
  rect(102,102,200,200);
  rect(698,102,200,200);
  rect(698,698,200,200);
  rect(102,696,200,200);
  
  drawFrontGate();
  for(int i = 150; i <900; i += 50){
    if(i == 150 || i == 200 || i == 800 || i == 850){
      stroke(0);
      strokeWeight(1);
      line(100, i, 900, i); 
    }
    stroke(0);
    strokeWeight(1);
    line(150, i, 850, i);
  }
  stroke(0);
  strokeWeight(1);
  line(100, 100, 200, 100);
  line(800, 100, 900, 100);
  line(100, 900, 200, 900);
  line(800, 900, 900, 900);
  for (int i = 0; i < numWaves; i++) {
    pushMatrix();
    translate(waveX[i], waveY[i]);
    rotate(PI);
    fill(#95D6FF);
    textSize(20);
    text("vvv", 0, 0);
    popMatrix();
  }
  fill(255);
  textSize(25);
  fill(0);
  textAlign(LEFT);
  text("Tilt to move the ball", 120, 130);
  text("Avoid breaking the walls!", 120, 185);
  text("Fix cracks to save lives!", 120, 230);
  textAlign(CENTER);
  fill(#F70C0C);
  text("Click the red button to return to the Menu Screen", width/2, 775);

  textSize(30);
  textAlign(CENTER);
  fill(255);
  text("The Castle is Sinking!", 500, 35);
  text("Help us repair the crack quickly!", 500, 75);

  windX = 0;
  windY = 0;
  processing_values[0] = 0;
  processing_values[1] = 0;
  sendSerialData();
  
  if (x < 100 + radius) x = 100 + radius;
  if (x > 900 - radius) x = 900 - radius;
  if (y < 100 + radius) y = 100 + radius;
  if (y > 900 - radius) y = 900 - radius;
  drawSharks();
}
void endlessGameMode(){
  background(#1A48E8);

  // Main castle body
  fill(#B4B4B4);
  stroke(#906C3D);
  strokeWeight(2);
  rect(100, 100, 800, 800);

  // Corner towers with battlements
  drawTower(50, 50);    // top left
  drawTower(750, 50);   // top right
  drawTower(50, 750);   // bottom left
  drawTower(750, 750);  // bottom right

  // Main wall battlements
  drawTopWall();
  drawBottomWall();
  drawLeftWall();
  drawRightWall();
  
  noStroke();
  rect(102,102,200,200);
  rect(698,102,200,200);
  rect(698,698,200,200);
  rect(102,696,200,200);
  
  drawFrontGate();
  for(int i = 150; i <900; i += 50){
    if(i == 150 || i == 200 || i == 800 || i == 850){
      stroke(0);
      strokeWeight(1);
      line(100, i, 900, i); 
    }
    stroke(0);
    strokeWeight(1);
    line(150, i, 850, i);
  }
  stroke(0);
  strokeWeight(1);
  line(100, 100, 200, 100);
  line(800, 100, 900, 100);
  line(100, 900, 200, 900);
  line(800, 900, 900, 900);
  for (int i = 0; i < numWaves; i++) {
    pushMatrix();
    translate(waveX[i], waveY[i]);
    rotate(PI);
    fill(#95D6FF);
    textSize(20);
    text("vvv", 0, 0);
    popMatrix();
  }
  if (millis() - lastWindChange > windInterval) {
    windX = random(-0.1, 0.1);  // horizontal wind
    windY = random(-0.1, 0.1);  // vertical wind (optional)
    
    processing_values[0] = int(windX * 100);
    processing_values[1] = int(windY * 100);
    sendSerialData();
    lastWindChange = millis();
  }
  fill(#A25D31);
  stroke(0);
  rect(400,100,200,10); //top fence
  rect(400,900,200,-10); //right fence
  rect(100,400,10,200); // left fence
  rect(900,400,-10,200); //bottom fence
  // TOP wall (y = 100, x from 400 to 600)
  if (y < 100 + radius && x > 400 && x < 600) {
    y = 100 + radius;
    velocity_y *= -1;
  }
  
  // BOTTOM wall (y = 900, x from 400 to 600)
  if (y > 900 - radius && x > 400 && x < 600) {
    y = 900 - radius;
    velocity_y *= -1;
  }
  
  // LEFT wall (x = 100, y from 400 to 600)
  if (x < 100 + radius && y > 400 && y < 600) {
    x = 100 + radius;
    velocity_x *= -1;
  }
  
  // RIGHT wall (x = 900, y from 400 to 600)
  if (x > 900 - radius && y > 400 && y < 600) {
    x = 900 - radius;
    velocity_x *= -1;
  }
  drawSharks();
}

void chaosGameMode(){
  background(#1A48E8);

  // Main castle body
  fill(#B4B4B4);
  stroke(#906C3D);
  strokeWeight(2);
  rect(100, 100, 800, 800);

  // Corner towers with battlements
  drawTower(50, 50);    // top left
  drawTower(750, 50);   // top right
  drawTower(50, 750);   // bottom left
  drawTower(750, 750);  // bottom right

  // Main wall battlements
  drawTopWall();
  drawBottomWall();
  drawLeftWall();
  drawRightWall();
  
  noStroke();
  rect(102,102,200,200);
  rect(698,102,200,200);
  rect(698,698,200,200);
  rect(102,696,200,200);
  
  drawFrontGate();
  for(int i = 150; i <900; i += 50){
    if(i == 150 || i == 200 || i == 800 || i == 850){
      stroke(0);
      strokeWeight(1);
      line(100, i, 900, i); 
    }
    stroke(0);
    strokeWeight(1);
    line(150, i, 850, i);
  }
  stroke(0);
  strokeWeight(1);
  line(100, 100, 200, 100);
  line(800, 100, 900, 100);
  line(100, 900, 200, 900);
  line(800, 900, 900, 900);
 
  for (int i = 0; i < numWaves; i++) {
    pushMatrix();
    translate(waveX[i], waveY[i]);
    rotate(PI);
    fill(#95D6FF);
    textSize(20);
    text("vvv", 0, 0);
    popMatrix();
  }
  
  if (millis() - lastWindChange > windInterval) {
    windX = random(-0.15, 0.15);  // horizontal wind
    windY = random(-0.15, 0.15);  // vertical wind (optional)
      
    processing_values[0] = int(windX * 100);
    processing_values[1] = int(windY * 100);
    sendSerialData();
    lastWindChange = millis();
  }
  drawSharks();
}
  
  
//making flipped "vvv" waves
void generateWaves(){
  for (int i = 0; i < 20; i++) {
    while (true) {
      float x = random(width);
      float y = random(height);
  
      if (x < 50 || x > 950 || y < 50 || y > 950) {
        waveX[i] = x;
        waveY[i] = y;
        break;
      }
    }
  }
}

void gameOver(){
  background(#244AFF);
  fill(#49C0CE);
  textAlign(CENTER);
  
  textSize(70);
  fill(0);
  stroke(255);
  strokeWeight(4);
  text("The castle sank faster than ", width/2, 300);
  text("your reaction time.", width/2, 400);
  textSize(50);
  if(chosenEndless){
  text("Final Time: " + nf(finalTime, 0, 2), width/2, 700);
  text("Survival Score: " + points, 500, 500);
  }
  if(chosenChaos){
  text("Lives Saved: " + points, 500, 500);
  }
  drawFrownyFace(width/2, 600);
  textAlign(CENTER);
  fill(#F70C0C);
  text("Press the red button to start over", 500, 800);
}
void resetGame() {
  unchosen = true;
  chosenEndless = false;
  chosenChaos = false;
  chosenTutorial = false;
  gameOver = false;

  x = width/2;
  y = height/2;
  velocity_x = 0;
  velocity_y = 0;

  points = 0;

  windX = 0;
  windY = 0;
  windOffsetX = 0;
  windOffsetY = 0;

  creviceActive = false;
  creviceX = 0;
  creviceY = 0;

  timerStarted = false;
  startTime = 0;
  creviceStarTtime = 0;

  friction = 0.99;
  scale_x = 0.5;
  scale_y = 0.5;

  generateWaves();
  processing_values[0] = 0;
  processing_values[1] = 0;
  sendSerialData();
}


void drawFrownyFace(float x, float y) {
  // face
  fill(255, 220, 0);
  noStroke();
  circle(x, y, 100);
  // eyes
  fill(0);
  circle(x - 20, y - 15, 10);
  circle(x + 20, y - 15, 10);
  // frown
  noFill();
  stroke(0);
  strokeWeight(3);
  arc(x, y + 15, 40, 30, PI, TWO_PI);
}

void spawnCrevice(){
  creviceX = random(200,800);
  creviceY = random(200,800);
  creviceActive = true;
}

void drawWind(){
  curve(480 + windOffsetX * 0.5, 480 + windOffsetY * 0.5,
        480 + windOffsetX * 0.5, 480 + windOffsetY * 0.5,
        752 + windOffsetX * 0.5, 472 + windOffsetY * 0.5,
        752 + windOffsetX * 0.5, 620 + windOffsetY * 0.5);
  
  curve(490 + windOffsetX * 0.5, 490 + windOffsetY * 0.5,
        490 + windOffsetX * 0.5, 490 + windOffsetY * 0.5,
        762 + windOffsetX * 0.5, 482 + windOffsetY * 0.5,
        762 + windOffsetX * 0.5, 630 + windOffsetY * 0.5);
  
  curve(500 + windOffsetX * 0.5, 500 + windOffsetY * 0.5,
        500 + windOffsetX * 0.5, 500 + windOffsetY * 0.5,
        772 + windOffsetX * 0.5, 492 + windOffsetY * 0.5,
        772 + windOffsetX * 0.5, 640 + windOffsetY * 0.5);
    //wind 2
  curve(120 + windOffsetX * 0.5, 120 + windOffsetY * 0.5,
        120 + windOffsetX * 0.5, 120 + windOffsetY * 0.5,
        392 + windOffsetX * 0.5, 112 + windOffsetY * 0.5,
        392 + windOffsetX * 0.5, 260 + windOffsetY * 0.5);
  
  curve(130 + windOffsetX * 0.5, 130 + windOffsetY * 0.5,
        130 + windOffsetX * 0.5, 130 + windOffsetY * 0.5,
        402 + windOffsetX * 0.5, 122 + windOffsetY * 0.5,
        402 + windOffsetX * 0.5, 270 + windOffsetY * 0.5);
  
  curve(140 + windOffsetX * 0.5, 140 + windOffsetY * 0.5,
        140 + windOffsetX * 0.5, 140 + windOffsetY * 0.5,
        412 + windOffsetX * 0.5, 132 + windOffsetY * 0.5,
        412 + windOffsetX * 0.5, 280 + windOffsetY * 0.5);
    //wind 3
  curve(720 + windOffsetX * 0.5, 120 + windOffsetY * 0.5,
        720 + windOffsetX * 0.5, 120 + windOffsetY * 0.5,
        992 + windOffsetX * 0.5, 112 + windOffsetY * 0.5,
        992 + windOffsetX * 0.5, 260 + windOffsetY * 0.5);

  curve(730 + windOffsetX * 0.5, 130 + windOffsetY * 0.5,
        730 + windOffsetX * 0.5, 130 + windOffsetY * 0.5,
        1002 + windOffsetX * 0.5, 122 + windOffsetY * 0.5,
        1002 + windOffsetX * 0.5, 270 + windOffsetY * 0.5);
    
  curve(740 + windOffsetX * 0.5, 140 + windOffsetY * 0.5,
        740 + windOffsetX * 0.5, 140 + windOffsetY * 0.5,
        1012 + windOffsetX * 0.5, 132 + windOffsetY * 0.5,
        1012 + windOffsetX * 0.5, 280 + windOffsetY * 0.5);
    
    //wind 4
  curve(120 + windOffsetX * 0.5, 720 + windOffsetY * 0.5,
        120 + windOffsetX * 0.5, 720 + windOffsetY * 0.5,
        392 + windOffsetX * 0.5, 712 + windOffsetY * 0.5,
        392 + windOffsetX * 0.5, 860 + windOffsetY * 0.5);

  curve(130 + windOffsetX * 0.5, 730 + windOffsetY * 0.5,
        130 + windOffsetX * 0.5, 730 + windOffsetY * 0.5,
        402 + windOffsetX * 0.5, 722 + windOffsetY * 0.5,
        402 + windOffsetX * 0.5, 870 + windOffsetY * 0.5);
  
  curve(140 + windOffsetX * 0.5, 740 + windOffsetY * 0.5,
        140 + windOffsetX * 0.5, 740 + windOffsetY * 0.5,
        412 + windOffsetX * 0.5, 732 + windOffsetY * 0.5,
        412 + windOffsetX * 0.5, 880 + windOffsetY * 0.5);
          
    //wind 5
  curve(720 + windOffsetX * 0.5, 720 + windOffsetY * 0.5,
        720 + windOffsetX * 0.5, 720 + windOffsetY * 0.5,
        992 + windOffsetX * 0.5, 712 + windOffsetY * 0.5,
        992 + windOffsetX * 0.5, 860 + windOffsetY * 0.5);
  
  curve(730 + windOffsetX * 0.5, 730 + windOffsetY * 0.5,
        730 + windOffsetX * 0.5, 730 + windOffsetY * 0.5,
        1002 + windOffsetX * 0.5, 722 + windOffsetY * 0.5,
        1002 + windOffsetX * 0.5, 870 + windOffsetY * 0.5);
  
  curve(740 + windOffsetX * 0.5, 740 + windOffsetY * 0.5,
        740 + windOffsetX * 0.5, 740 + windOffsetY * 0.5,  
        1012 + windOffsetX * 0.5, 732 + windOffsetY * 0.5,
        1012 + windOffsetX * 0.5, 880 + windOffsetY * 0.5);
}
  
void drawTower(int x, int y) {
  fill(#B4B4B4);
  stroke(0);
  strokeWeight(2);
  rect(x, y, 200, 200);

  noStroke();
  if (x < 100) {
    if (y < 100) rect(x + 52, y + 52, 200, 200);
    else rect(x + 52, y - 48, 200, 200);
  } else {
    if (y < 100) rect(x - 48, y + 52, 200, 200);
    else rect(x - 48, y - 48, 200, 200);
  }

  // Tower battlements (all 4 sides)
  stroke(0);
  fill(#B4B4B4);

  // Top edge
  for (int i = x; i <= x + 150; i += 50) {
    rect(i, y - 20, 25, 20);
  }

  // Bottom edge
  for (int i = x; i <= x + 150; i += 50) {
    rect(i, y + 200, 25, 20);
  }

  // Left edge
  for (int j = y; j <= y + 150; j += 50) {
    rect(x - 20, j, 20, 25);
  }

  // Right edge
  for (int j = y; j <= y + 150; j += 50) {
    rect(x + 200, j, 20, 25);
  }
}

void drawTopWall() {
  for (int x = 250; x < 750; x += 50) {
    rect(x, 70, 25, 30);
  }
}

void drawBottomWall() {
  for (int x = 250; x < 750; x += 50) {
    rect(x, 900, 25, 30);
  }
}

void drawLeftWall() {
  for (int y = 250; y < 750; y += 50) {
    rect(70, y, 30, 25);
  }
}

void drawRightWall() {
  for (int y = 250; y < 750; y += 50) {
    rect(900, y, 30, 25);
  }
}
void drawFrontGate() {
  // Cover wall battlements behind gate completely
  noStroke();
  fill(#B4B4B4);
  rect(450, 870, 10, 40);

  // Gate
  fill(#5A3A1A);
  stroke(0);
  strokeWeight(3);

  // Main wooden doors
  rect(450, 875, 100, 25);

  // Center split
  line(500, 875, 500, 900);

  // Wooden braces
  line(468, 880, 495, 895);
  line(505, 880, 532, 895);

  // Arch
  noFill();
  arc(500, 875, 100, 40, PI, TWO_PI);

   // Remove battlements where gate is
  noStroke();
  fill(#1A48E8);
  rect(425, 900, 150, 35);

  fill(#8B8B8B);
  stroke(0);
  rect(450, 900, 100, 100);
}

void drawSharks(){
  stroke(0);
  strokeWeight(3);
  line(50, 400, 60, 380);
  line(60, 380, 70, 400);
  noStroke();
  fill(#A1A4AA);
  triangle(50, 400, 60, 380, 70, 400);
  noFill();
  stroke(#6F96FF);
  strokeWeight(2);

  beginShape();
  for (int x = 40; x <= 80; x++) {   // extends 10 past both sides
    float y = 400 + sin((x - 40) * 0.3) * 3;  // wider waves
    vertex(x, y);
  }
  endShape();
  
  stroke(0);
  strokeWeight(3);
  line(950, 600, 960, 580);
  line(960, 580, 970, 600);
  noStroke();
  fill(#A1A4AA);
  triangle(950, 600, 960, 580, 970, 600);
  noFill();
  stroke(#6F96FF);
  strokeWeight(2);

  beginShape();
  for (int x = 940; x <= 980; x++) {   // moved to right side
    float y = 600 + sin((x - 940) * 0.3) * 3;
    vertex(x, y);
  }
  endShape();
}
// the helper function below receives the values from Arduino
// in the "arduino_values" array from a connected Arduino
// running the "serial_AtoP_arduino" sketch
// (You won't need to change this code.)
void getSerialData() {
  while (serialPort.available() > 0) {
    String in = serialPort.readStringUntil( 10 );  // 10 = '\n'  Linefeed in ASCII
    if (in != null) {
      print("From Arduino: " + in);
      String[] serialInArray = split(trim(in), ",");
      if (serialInArray.length == NUM_OF_VALUES_FROM_ARDUINO) {
        for (int i=0; i<serialInArray.length; i++) {
          arduino_values[i] = int(serialInArray[i]);
        }
      }
    }
  }
}
// the helper function below sends the variables
// in the "processing_values" array to a connected Arduino
// running the "serial_read_and_write_arduino" sketch
// (You won't need to change this code.)

void sendSerialData() {
  String data = "";
  for (int i=0; i<processing_values.length; i++) {
    data += processing_values[i];
    // if i is less than the index number of the last element in the values array
    if (i < processing_values.length-1) {
      data += ",";  // add splitter character "," between each values element
    }
    // if it is the last element in the values array
    else {
      data += "\n";  // add the end of data character "n"
    }
  }
  // write to Arduino
  serialPort.write(data);
  print("To Arduino: " + data);  // this prints to the console the values going to Arduino
}
