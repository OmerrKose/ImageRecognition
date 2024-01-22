//
//  ViewController.swift
//  ImageRecognition
//
//  Created by Ömer Köse on 7.01.2024.
//

import UIKit
import Foundation
import PhotosUI

class ImageSelectionViewController: UIViewController {
    @IBOutlet var imageSelectionView: UIView!
    @IBOutlet weak var imageSelectionScrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionTextField: UITextView!
    @IBOutlet weak var searchImageButton: UIButton!
    @IBOutlet weak var addPhotoButton: UIBarButtonItem!
    @IBOutlet weak var descriptionTextFieldHeight: NSLayoutConstraint!
    private let imageClassifierWrapper = ImageClassifierWrapper()
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBar()
        setImageView()
        setMediaButton(for: nil, buttonColor: .lightGray, isEnabled: false)
        setDescriptionTextField(with: nil)
        setTextViewNotification()
    }
    @IBAction func scanImageButtonClicked(_ sender: Any) {
        openMediaSelectionMenu()
    }
    @IBAction func searchImageButtonPressed(_ sender: UIButton) {
    }
}
// MARK: - View Methods
extension ImageSelectionViewController {
    private func setNavigationBar() {
        title = Titles.navigationBarTitle
        addPhotoButton.image = UIImage(systemName: ImageNames.addPhotoButtonImage)
        addPhotoButton.tintColor = .white
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    private func setMediaButton(for title: String?, buttonColor: UIColor, isEnabled: Bool) {
        searchImageButton.setTitle(title ?? ButtonTitles.selectMediaButtonTitleDefault, for: .normal)
        searchImageButton.titleLabel?.font = UIFont(name: "system", size: 18)
        searchImageButton.tintColor = .white
        searchImageButton.backgroundColor = buttonColor
        searchImageButton.layer.borderWidth = 0.3
        searchImageButton.layer.cornerRadius = 10
        searchImageButton.layer.borderColor = UIColor.black.cgColor
        searchImageButton.isUserInteractionEnabled = isEnabled
    }
    private func openCameraPicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    private func openGalleryPicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selection = .continuous
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    private func detectFromImage() {
        if let userSelectedImage = imageView.image, userSelectedImage != UIImage(systemName: ImageNames.imageViewDefaultImage){
            guard let ciImage = CIImage(image: userSelectedImage as UIImage) else {
                fatalError("Error: Can not convert user image to CIImage")
            }
            let resultOfSearch = imageClassifierWrapper.ClassifyImage(image: ciImage)
            setDescriptionTextField(with: resultOfSearch)
        } else {
            showAlert(title: Texts.emptyImageAlertTitle, message: Texts.emptyImageDescription)
        }
    }
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(alertAction)
        present(alert, animated: true)
    }
}
// MARK: - Image View Methods
extension ImageSelectionViewController {
    private func setImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.image = UIImage(systemName: ImageNames.imageViewDefaultImage)
    }
    private func didImageChanged(for image: UIImage) {
        let aspectRatio = image.size.width / image.size.height
        let maxWidth: CGFloat = 300
        let maxHeight: CGFloat = 500
        var imageViewWidth: CGFloat
        var imageViewHeight: CGFloat
        if aspectRatio > 1 { // Horizontal image
            imageViewWidth = min(maxWidth, image.size.width)
            imageViewHeight = imageViewWidth / aspectRatio
        } else { // Vertical image
            imageViewHeight = min(maxHeight, image.size.height)
            imageViewWidth = imageViewHeight * aspectRatio
        }
        imageView.frame = CGRect(x: 0, y: 0, width: imageViewWidth, height: imageViewHeight)
        imageView.layoutIfNeeded()
    }
}
// MARK: - Text View Methods
extension ImageSelectionViewController {
    private func setTextViewNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidChange), name: UITextView.textDidChangeNotification, object: descriptionTextField)
    }
    private func setDescriptionTextField(with text: String?) {
        descriptionTextField.text = text ?? Texts.descriptionTextFieldDefaultText
        descriptionTextField.textColor = .darkGray
        descriptionTextField.isUserInteractionEnabled = false
    }
    @objc private func textViewDidChange(_ notification: Notification) {
        descriptionTextFieldHeight.constant = descriptionTextField.contentSize.height
        imageSelectionScrollView.layoutIfNeeded()
    }
}
// MARK: - UIAlertAction Menu
extension ImageSelectionViewController {
    private func openMediaSelectionMenu() {
        let menu = UIAlertController(title: Titles.selectionMenuTitle, message: nil, preferredStyle: .actionSheet)
        let selectFromCameraAction = UIAlertAction(title: MenuButtonTitles.cameraSelectionMenuButton, style: .default) { _ in
            self.openCameraPicker()
        }
        selectFromCameraAction.setValue(UIImage(
                                        systemName: ImageNames.cameraSelectionMenuButtonImage),
                                        forKey: "image")
        let selectFormPhotosAction = UIAlertAction(title: MenuButtonTitles.photosSelectionMenuButton, style: .default) { _ in
            self.openGalleryPicker()
        }
        selectFormPhotosAction.setValue(UIImage(
                                        systemName: ImageNames.photosSelectionMenuButtonImage),
                                        forKey: "image")
        let cancelSelectionAction = UIAlertAction(title: MenuButtonTitles.cancelSelectionMenuButton, style: .cancel) { _ in }
        cancelSelectionAction.setValue(UIImage(
                                        systemName: ImageNames.cancelSelectionMenuButtonImage),
                                        forKey: "image")
        cancelSelectionAction.setValue(UIColor.red, forKey: "titleTextColor")
        menu.addAction(selectFromCameraAction)
        menu.addAction(selectFormPhotosAction)
        menu.addAction(cancelSelectionAction)
        present(menu, animated: true)
    }
}
// MARK: - PHPickerViewControllerDelegate
extension ImageSelectionViewController: PHPickerViewControllerDelegate  {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true, completion: nil)
        guard let selectedImage = results.first?.itemProvider else {
            return
        }
        if selectedImage.canLoadObject(ofClass: UIImage.self) {
            selectedImage.loadObject(ofClass: UIImage.self) { image, error in
                if let image = image as? UIImage {
                    DispatchQueue.main.async {
                        self.imageView.image = image
                        self.didImageChanged(for: image)
                        self.setDescriptionTextField(with: Texts.descriptionTextFieldPressButtonMessage)
                        self.setMediaButton(for: ButtonTitles.selectMediaButtonTitle, buttonColor: .green, isEnabled: true)
                        self.detectFromImage()
                    }
                }
            }
        }
    }
}
// MARK: - UIImagePickerControllerDelegate - UINavigationControllerDelegate
extension ImageSelectionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.imageView.image = selectedImage
            self.didImageChanged(for: selectedImage)
            self.setDescriptionTextField(with: Texts.descriptionTextFieldPressButtonMessage)
            self.setMediaButton(for: ButtonTitles.selectMediaButtonTitle, buttonColor: .green, isEnabled: true)
            self.detectFromImage()
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
