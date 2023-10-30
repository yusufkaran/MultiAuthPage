//
//  CustomTextField.swift
//  MultiAuthPage
//
//  Created by Yusuf Karan on 28.10.2023.
//

import SwiftUI

struct CustomTextField: View {
    var hint: String
    @Binding var text: String
    
    //MARK: View Properties
    @FocusState var isEnable: Bool
    var contentType: UITextContentType = .telephoneNumber
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            TextField(hint, text: $text)
                .keyboardType(.numberPad)
                .textContentType(contentType)
                .focused($isEnable) // belki duz isEnable olabilir
            
            ZStack(alignment: .leading){
                Rectangle()
                    .fill(.black.opacity(0.2))
                
                Rectangle()
                    .fill(.black)
                    .frame(width: isEnable ? nil : 0, alignment: .leading)
                    .animation(.easeInOut(duration: 0.3), value: isEnable)
                
            }
            .frame(height: 2)
        }
    }
}

struct CustomTextField_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
