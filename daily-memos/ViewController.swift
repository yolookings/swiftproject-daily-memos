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
        recordButton.accessibilityLabel = "Tombol Rekam"
        recordButton.accessibilityHint = "Ketuk untuk memulai atau menghentikan rekaman"
    }

    func requestMicrophonePermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("Microphone access granted (iOS 17+)")
                    } else {
                        self.showAlert(title: "Izin Ditolak", message: "Aplikasi memerlukan akses mikrofon untuk merekam.")
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    if allowed {
                        print("Microphone access granted (iOS <17)")
                    } else {
                        self.showAlert(title: "Izin Ditolak", message: "Aplikasi memerlukan akses mikrofon untuk merekam.")
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
        do {
            let files = try FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil)
            recordings = files.filter { $0.pathExtension == "m4a" }.sorted { $0.lastPathComponent > $1.lastPathComponent }
            tableView.reloadData()
        } catch {
            print("Gagal memuat rekaman: \(error.localizedDescription)")
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
        stopPlaybackIfNeeded()

        let audioFilename = generateFileName()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()

            isRecording = true
            updateRecordButtonUI(isRecording: true)
        } catch {
            finishRecording(success: false)
            print("Gagal memulai rekaman: \(error.localizedDescription)")
            showAlert(title: "Error", message: "Tidak dapat memulai rekaman.")
        }
    }

    func finishRecording(success: Bool) {
        audioRecorder?.stop()
        audioRecorder = nil

        isRecording = false
        updateRecordButtonUI(isRecording: false)

        if success {
            loadRecordings()
        } else {
            showAlert(title: "Rekaman Gagal", message: "Terjadi kesalahan saat merekam.")
        }
    }

    func stopPlaybackIfNeeded() {
        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
        }
    }

    func updateRecordButtonUI(isRecording: Bool) {
        if isRecording {
            recordButton.setTitle("Stop Rekaman", for: .normal)
            recordButton.backgroundColor = .systemRed
            recordButton.accessibilityLabel = "Tombol Stop"
            recordButton.accessibilityHint = "Ketuk untuk menghentikan rekaman"
        } else {
            recordButton.setTitle("Mulai Rekam", for: .normal)
            recordButton.backgroundColor = .systemBlue
            recordButton.accessibilityLabel = "Tombol Rekam"
            recordButton.accessibilityHint = "Ketuk untuk memulai rekaman"
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
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func playRecording(url: URL) {
        stopPlaybackIfNeeded()

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Gagal memutar rekaman: \(error.localizedDescription)")
            showAlert(title: "Playback Error", message: "Rekaman tidak dapat diputar.")
        }
    }

    // MARK: - Alert Helper

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Oke", style: .default))
        present(alert, animated: true)
    }
}
