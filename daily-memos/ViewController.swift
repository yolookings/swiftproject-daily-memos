import UIKit
import AVFoundation

class ViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lastRecordingButton: UIButton!
    @IBOutlet weak var waveformImageView: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var enterTitleLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!

    // MARK: - Audio Properties
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var lastRecordingURL: URL?
    var isRecording = false
    var isPlaying = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestMicrophonePermission()
        loadLastRecording()
    }

    func setupUI() {
        enterTitleLabel.text = "Enter Title"
        titleTextField.placeholder = "Type your title journey"
        waveformImageView.image = UIImage(named: "waveform-placeholder")
    }

    func requestMicrophonePermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        self.showAlert(title: "Izin Ditolak", message: "Aplikasi memerlukan akses mikrofon untuk merekam.")
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    if !allowed {
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

    func loadLastRecording() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil)
            let recordings = files.filter { $0.pathExtension == "m4a" }.sorted { $0.lastPathComponent > $1.lastPathComponent }
            lastRecordingURL = recordings.first
        } catch {
            print("Gagal memuat rekaman: \(error.localizedDescription)")
        }
    }

    // MARK: - Actions
    @IBAction func lastRecordingButtonTapped(_ sender: UIButton) {
        guard let url = lastRecordingURL else { return }
        playRecording(url: url)
    }

    @IBAction func playButtonTapped(_ sender: UIButton) {
        print("Play button got tapped.")
        guard let url = lastRecordingURL else { return }
        playRecording(url: url)
    }

    @IBAction func pauseButtonTapped(_ sender: UIButton) {
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
        }
    }

    @IBAction func endButtonTapped(_ sender: UIButton) {
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
        }
        if isRecording {
            finishRecording(success: true)
        }
    }

    @IBAction func saveButtonTapped(_ sender: UIButton) {
        // Simpan judul dan file rekaman terakhir
        guard let url = lastRecordingURL, let title = titleTextField.text, !title.isEmpty else {
            showAlert(title: "Error", message: "Judul tidak boleh kosong.")
            return
        }
        // Di sini bisa ditambahkan logika untuk menyimpan judul ke database/file
        showAlert(title: "Berhasil", message: "Rekaman disimpan ke Library dengan judul: \(title)")
    }

    @IBAction func homeButtonTapped(_ sender: UIButton) {
        showAlert(title: "Home", message: "Home section tapped.")
    }

    @IBAction func searchButtonTapped(_ sender: UIButton) {
        showAlert(title: "Search", message: "Search section tapped.")
    }

    @IBAction func profileButtonTapped(_ sender: UIButton) {
        showAlert(title: "Profile", message: "Profile section tapped.")
    }

    // MARK: - Audio Logic
    func startRecording() {
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
            lastRecordingURL = audioFilename
        } catch {
            finishRecording(success: false)
            showAlert(title: "Error", message: "Tidak dapat memulai rekaman.")
        }
    }

    func finishRecording(success: Bool) {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        if success {
            loadLastRecording()
        } else {
            showAlert(title: "Rekaman Gagal", message: "Terjadi kesalahan saat merekam.")
        }
    }

    func playRecording(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
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
