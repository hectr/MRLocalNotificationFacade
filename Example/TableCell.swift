
import UIKit

class TableCell: UITableViewCell {

    @IBOutlet weak var alertTitleTextfield: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    func setUp(notification: UILocalNotification) {
        if (notification.fireDate!.timeIntervalSinceNow > 0) {
            alertTitleTextfield.alpha = 1
            datePicker.alpha = 1
        } else {
            alertTitleTextfield.alpha = 0.5
            datePicker.alpha = 0.5
        }
        alertTitleTextfield.text = notification.alertBody
        datePicker.date = notification.fireDate!
    }
    
}
