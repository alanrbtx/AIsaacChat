//
//  ContentView.swift
//  SwiftUITest
//
//  Created by Alan Barsag on 17.10.2022.
//

import SwiftUI
import Speech
import AVKit
import UIKit

private var text = ""
public var responseStr = ""
private var responcePadding: CGFloat = 10
private var responseBackground = Color(uiColor: .black)
private var responseTestText = ""
private var textColor = Color.white
private var color = Color(UIColor.systemCyan)
private var circleScale: CGFloat = 1
private var inputString = ""
private var synthesizer = AVSpeechSynthesizer()
private var imageData: Data? = nil
private var timerToggle = false



func createUtterance(inputString: String, language: String, pitch: Float, rate: Float, sintesizer: AVSpeechSynthesizer) {
    let utterance = AVSpeechUtterance(string: inputString)
    utterance.voice = AVSpeechSynthesisVoice(language: language)
    utterance.pitchMultiplier = pitch
    utterance.volume = 1.0
    utterance.rate = rate
    sintesizer.speak(utterance)
}

extension Animation {
    func `repeat`(while expression: Bool, autoreverses: Bool = true) -> Animation {
        if expression {
            return self.repeatForever(autoreverses: autoreverses)
        } else {
            return self
        }
    }
}



class SoundManager: ObservableObject {
    var secondAudio: AVAudioPlayer?
    
    func playSound(sound: String) {
        if let url = URL(string: sound) {
            do {
                self.secondAudio = try AVAudioPlayer(contentsOf: url)

            } catch {
                
            }
            
        }
    }
    
}

class TimerManager: ObservableObject {
    @Published var timer: Timer?
    @Published var timeRemaining = 0.0
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            if self.timeRemaining >= 0 {
                self.timeRemaining += 0.01
            } else {
                self.timer?.invalidate()
                // Выполните действия по истечении времени ожидания, например, обработку отсутствия ответа от сервера
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        timeRemaining = 0.0 // Сбрасываем время ожидания при остановке таймера
    }
}

 



struct ContentView: View {
    @State private var toggle = true
    @State private var circleWidth: CGFloat = 80
    @State private var padding: CGFloat = 15
    @State private var animateCircle: Bool = true
    
    @ObservedObject var speechRec = SpeechRec()
    @ObservedObject var testResponce = TestRequest()
    @StateObject private var soundManager = SoundManager()
    @StateObject var timerManager = TimerManager()
    
    
    var body: some View {
        ZStack() {
            Color(uiColor: .black)
                .ignoresSafeArea()
            
            VStack() {
                
                Image("component")
                    .resizable()
                    .frame(width: 100, height: 80)
                
                
                Spacer()
                
               
                HStack() {
                    Image("conversation")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .animation(.default, value: text)
                        .padding(.horizontal, 5)
                    Spacer()
                    Text("[нажмите на кнопку внизу экрана, чтобы начать общение с ассистентом]")
                        .padding(.top, 15)
                        .padding(.horizontal, 5)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .animation(.default, value: text)
                    Spacer()
                }
                
                HStack() {
                    Image("generate4")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .animation(.default, value: text)
                        .padding(.horizontal, 5)
                    Spacer()
                    Text("[скажите 'нарисуй [ваш запрос]', чтобы бот сгенерировал изображение]")
                        .padding(.top, 15)
                        .padding(.horizontal, 5)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .animation(.default, value: text)
                    Spacer()
                }

                Text(text)
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .padding(.all, self.padding)
                    .background(Color.black)
                    .cornerRadius(10)
                    .animation(.default, value: text)
                
                if !self.toggle {
                    Button(action: {
                        self.toggle = !self.toggle
                        self.padding = 10
                        circleScale = 1
                        self.speechRec.stopListening()
                        textColor = Color.white
                        
                        text = ""
                        self.animateCircle = false
                        let sound = Bundle.main.path(forResource: "test_sound_stop", ofType: "mp3")
                        self.soundManager.playSound(sound: sound!)
                        self.soundManager.secondAudio?.play()
                        
                    }) {
                        Text("×")
                            .font(.system(size: 50))
                            .padding()
                            .background(Color(uiColor: .black))
                            .foregroundColor(Color(uiColor: .systemGray5))
                            .cornerRadius(5)
                    }
                }
               
               
                if timerToggle {
                    Text("\(String(format: "%.2f", timerManager.timeRemaining)) seconds")
                        .font(.system(size: 20))
                        .padding()
                        .foregroundColor(.white)
                    
                                        
                }
                    
                ZStack() {
                    
                    if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                        VStack() {
                            Spacer()
                            Image(uiImage: uiImage)
                                                                                       .resizable()
                                                                                       .scaledToFit()
                                                                                       .cornerRadius(15)
                                                                                       .animation(.default, value: text)
                            Spacer()
                        }
                                                       
                        
                                        Button(action: {
                                            DispatchQueue.main.async {
                                                
                                                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                                            }
                                        }) {
                                            Image("download").resizable().frame(width: 50, height: 50)
                                                .animation(.default, value: text)
                                        }
                        
                        
                                    } else {
                                        Text(responseStr)
                                            .font(.title3)
                                            .foregroundColor(textColor)
                                            .padding(.all, responcePadding)
                                            .background(responseBackground)
                                            .cornerRadius(10)
                                            .animation(.default, value: text)

                                    }
                }.animation(.default, value: text)
                
                
                Spacer()

                ZStack() {
                    Circle()
                        .frame(width: self.circleWidth, height: self.circleWidth, alignment: .center)
                        .scaleEffect(circleScale*1.2)
                        .foregroundColor(.black)
                        .animation(.easeInOut.repeat(while: animateCircle).speed(1.4), value: circleScale)
                    Circle()
                        .scaleEffect(circleScale)
                        .animation(.easeInOut.repeat(while: animateCircle).speed(1.4), value: circleScale)
                        .frame(width: self.circleWidth, height: self.circleWidth, alignment: .center)
                        .foregroundColor(color)
                    Circle()
                        .frame(width: self.circleWidth, height: self.circleWidth, alignment: .center)
                        .scaleEffect(circleScale*0.8)
                        .foregroundColor(.black)
                        .animation(.easeInOut.repeat(while: animateCircle).delay(0.1).speed(1.4), value: circleScale)
                        .onTapGesture {
                            if !self.toggle {
                                self.toggle = !self.toggle
                                self.padding = 10
                                circleScale = 1
                                self.speechRec.stopListening()
                                textColor = Color.white
                                self.testResponce.postRequestFunc(command: text, timer: timerManager)
                                text = ""
                                self.animateCircle = false
                                let sound = Bundle.main.path(forResource: "test_sound_stop", ofType: "mp3")
                                self.soundManager.playSound(sound: sound!)
                                self.soundManager.secondAudio?.play()
                                //self.soundManager.secondAudio?.stop()
                                timerToggle = true
                                self.timerManager.startTimer()
                                imageData = nil
                            } else {
                                self.toggle = !self.toggle
                                circleScale = 1.1
                                self.padding = 40
                                self.speechRec.start()
                                responcePadding = 15
                                textColor = Color.white
                                responseStr = ""
                                self.animateCircle = true
                            }
                    }
                    
                }
                            

            }.animation(.default, value: responseStr)
            
        }
        
    }
    
}
    

class SpeechRec: ObservableObject {
    @Published private(set) var recognizedText = ""
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    
    func start() {
        self.recognizedText = "Слушаю..."
        text = self.recognizedText
        SFSpeechRecognizer.requestAuthorization { status in
            self.startRecognition()
        }
    }
    
    func startRecognition() {
        do {
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                if let result = result {
                    self.recognizedText = result.bestTranscription.formattedString
                    text = "«" + self.recognizedText + "»"
                }
            }
            
            let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
            audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
        }
        
        catch {
            
        }
    }
    
    func startListening() {
        do{
            try audioEngine.start()
        } catch {
            print(error)
        }
    }
    
    func stopListening() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        recognitionRequest = nil
        recognitionTask = nil
        print(self.recognizedText)
        self.recognizedText = "test"
        print("Response test: ", responseStr)
        
    }
    
}


class TestRequest: ObservableObject {
    @Published private(set) var responseText = ""
    @Published private(set) var image: Data? = nil
    
    
    
    
    
    func postRequestFunc(command: String, timer: TimerManager) {
        let data: [String: Any] = ["data": ["value": command]]
        let url = URL(string: "https://7971-5-35-152-85.ngrok-free.app/generate")
        guard let requestUrl = url else { fatalError() }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        let jsonData = try? JSONSerialization.data(withJSONObject: data)
        request.setValue("\(String(describing: jsonData?.count))", forHTTPHeaderField: "Content-Length")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        let timer = timer
        
                   
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Error took place \(error)")
                    print("Ошибка")
                    self.responseText = "Видимо на сервер пришло слишком много запросов, попробуйте позже"
                    responseStr = self.responseText
                    return
                }
            
            
          
            }

            DispatchQueue.main.async {
                let data = Data.init(data!)
                self.image = data
                imageData = self.image
                timerToggle = false
                timer.stopTimer()
                
                if response!.mimeType == "text/html" {
                    self.responseText = "[Видимо, на сервер пришло слишком много запросов, попробуйте позже]"
                    responseStr = self.responseText
                }
            }
            
            
                if let dataString = String(data: data!, encoding: .utf8) {
                    if dataString == "None" {
                        DispatchQueue.main.async {
                            self.responseText = "Намерения не распознаны"
                            responseStr = self.responseText
                            color = Color(UIColor.systemCyan)
                            inputString = self.responseText
                            timerToggle = false
                            timer.stopTimer()
                            
                            if response!.mimeType == "text/html" {
                                self.responseText = "[Видимо, на сервер пришло слишком много запросов, попробуйте позже]"
                                responseStr = self.responseText
                            }
                        }
                        responseBackground = Color(UIColor.black)
                        
                    } else {
                        DispatchQueue.main.async {
                            self.responseText = dataString
                            responseStr = self.responseText
                            color = Color(UIColor.systemCyan)
                            inputString = self.responseText
                            timerToggle = false
                            timer.stopTimer()
                            
                            if response!.mimeType == "text/html" {
                                self.responseText = "[Видимо, на сервер пришло слишком много запросов, попробуйте позже]"
                                responseStr = self.responseText
                            }
                        }
                        responseBackground = Color(UIColor.black)
                    }
                    
                }
            
        }
        task.resume()
        
    }
}
