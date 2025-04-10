import UIKit
import AVFoundation

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var recordings: [URL] = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var recordButton: UIButton!
    
    var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestMicrophonePermission()
        loadRecordings()
    }
    
    func setupUI() {
        tableView.dataSource = self
        tableView.delegate = self
        recordButton.layer.cornerRadius = 12
        recordButton.backgroundColor = .systemBlue
        recordButton.setTitle("Mulai Rekam", for: .normal)
        recordButton.setTitleColor(.white, for: .normal)
    }
    
    func requestMicrophonePermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("Microphone access granted (iOS 17+)")
                    } else {
                        print("Microphone access denied (iOS 17+)")
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("Microphone access granted (iOS <17)")
                    } else {
                        print("Microphone access denied (iOS <17)")
                    }
                }
            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func generateFileName() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "rekaman_\(formatter.string(from: Date())).m4a"
        return getDocumentsDirectory().appendingPathComponent(filename)
    }
    
    func loadRecordings() {
        let fileManager = FileManager.default
        let documentsURL = getDocumentsDirectory()
        
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            recordings = files.filter { $0.pathExtension == "m4a" }.sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
            tableView.reloadData()
        } catch {
            print("Gagal memuat rekaman: \(error)")
        }
    }
    
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        if isRecording {
            finishRecording(success: true)
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        let audioFilename = generateFileName()
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            
            isRecording = true
            recordButton.setTitle("Stop Rekaman", for: .normal)
            recordButton.backgroundColor = .systemRed
        } catch {
            finishRecording(success: false)
        }
    }
    
    func finishRecording(success: Bool) {
        audioRecorder?.stop()
        audioRecorder = nil
        
        isRecording = false
        recordButton.setTitle("Mulai Rekam", for: .normal)
        recordButton.backgroundColor = .systemBlue
        
        if success {
            loadRecordings()
        } else {
            print("Rekaman gagal")
        }
    }
    
    // MARK: - UITableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordingCell", for: indexPath)
        let fileURL = recordings[indexPath.row]
        cell.textLabel?.text = fileURL.lastPathComponent
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        playRecording(url: recordings[indexPath.row])
    }
    
    func playRecording(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Gagal memutar rekaman: \(error)")
        }
    }
}
