
import Foundation

class FeedbackViewController: BaseViewController {
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var sendView: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var insuredName: UILabel!
    @IBOutlet weak var insuredNumber: UILabel!
    @IBOutlet weak var accessor: UIImageView!
    @IBOutlet weak var feedbackErrorLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    var progressHud: MBProgressHUD?
    var user: User!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTapGesture()
        setupTextView()
        setupInsuredView()
    }

    func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGestureSelector))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc func handleTap(sender: UITapGestureRecognizer? = nil) {
        let storyboard = UIStoryboard(name: "Declaration", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "OpenNames") as! ChooseNameViewController
        vc.delegate = self
        vc.items.append(user)

        for coInsured in user.coInsured {
            vc.items.append(coInsured)
        }

        self.present(vc, animated: true, completion: nil)
    }

    func setDeclaratieName() {
        insuredName.text = user.name
        insuredNumber.text = user.insurance_number
        if user.coInsured.count > 0 {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            headerView.addGestureRecognizer(tap)
            accessor.isHidden = false
        } else {
            accessor.isHidden = true
        }
    }

    func setupInsuredView() {
        CustomerSession.current().userProxy.getUserWithSuccessBlock({ (user) in
            self.user = user
            self.setDeclaratieName()
        }, failure: { _ in
            self.navigationController?.popViewController(animated: true)
        })
    }

    func setupTextView() {
        let placeholdertext = NSLocalizedString("contact_feedback_placeholder", comment: "")
        textView.setPlaceholderText(placeholdertext)
    }

    @objc func tapGestureSelector() {
        textView.resignFirstResponder()
    }

    @IBAction func sendFeedbackButtonTouched(_ sender: UIButton, forEvent event: UIEvent) {
        sendFeedback()
    }

    func sendFeedback() {
        showProgressHUD()
        SentFeedbackManager.sentFeedback(insuranceNumber: insuredNumber.text!, feedback: textView.text, email:user.emailAddress , success: {
            self.hideProgressHUD()
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "sentFeedback", sender: self)
            }
        }, failure: { (_) in
            self.hideProgressHUD()
            self.handleError()
        })
    }

    func handleError() {
        let title = NSLocalizedString("alert_message_generalError_title", comment: "")
        let message = NSLocalizedString("alert_message_generalError", comment: "")

        let tryAgain = NSLocalizedString("alert_action_tryAgain", comment: "")
        let cancel = NSLocalizedString("misc_cancel", comment: "")

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: tryAgain, style: .default, handler: { (_) in
            self.sendFeedback()
        }))

        alert.addAction(UIAlertAction(title: cancel, style: .destructive, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func showProgressHUD() {
        DispatchQueue.main.async {
            MBProgressHUD.showAdded(to: self.view, animated: true)
        }
    }

    func hideProgressHUD() {
        DispatchQueue.main.async {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? FeedbackSentViewController {
            destination.feedbackText = self.textView.text
            destination.nameOfInsured = self.insuredName.text
            destination.insuranceNumberOfInsured = self.insuredNumber.text
        }
    }
}

extension FeedbackViewController: listOfNamesDelegate {
    func changeName(value: String) {
        insuredName.text = value
        if value != self.user.name {
            insuredNumber.text = self.user.getCoInsured(byName: value).insurance_number
        } else {
            insuredNumber.text = self.user.insurance_number
        }
    }
}

extension FeedbackViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView == self.textView {
        for constraint in textView.constraints where constraint.identifier == "height" && textView.contentSize.height <= 100 {
                constraint.constant = textView.contentSize.height + 20 // +20 for extra margin
        }
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
      
       if textView == self.textView {
            feedbackErrorLabel.isHidden = true
            textView.layer.borderWidth = 0.0
        }
        if textView.textColor == .lightGreyThree() {
            textView.text = nil
            textView.textColor = .charcoalGrey()
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty && textView == self.textView {
            let placeholderText = NSLocalizedString("contact_feedback_placeholder", comment: "")
            textView.layer.borderColor = UIColor.red.cgColor
            textView.layer.borderWidth = 1.0
            feedbackErrorLabel.isHidden = false
            feedbackErrorLabel.text = NSLocalizedString("contact_feedback_error_message", comment: "")
            textView.setPlaceholderText(placeholderText)
        }
        if !self.textView.text.isEmpty && self.textView.text! != NSLocalizedString("contact_feedback_placeholder", comment: "") {
            sendButton.isEnabled = true
        } else {
            sendButton.isEnabled = false
        }
    }
}

private extension UITextView {
    func setPlaceholderText(_ placeholderText: String) {
        textColor = .lightGreyThree()
        text = placeholderText
    }
}
