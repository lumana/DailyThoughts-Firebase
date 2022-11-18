/// Copyright (c) 2021 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import FirebaseAuth
import FirebaseDatabase
import SwiftUI

final class JournalModelController: ObservableObject {
  @Published var thoughts: [ThoughtModel] = []
  @Published var newThoughtText: String = ""
  
  private lazy var databasePath: DatabaseReference? = {
    // Gets the user ID of the authenticated user.
    guard let uid = Auth.auth().currentUser?.uid else {
      return nil
    }

    // Returns a reference to the path in your database where you want to store data.
    let ref = Database.database()
      .reference()
      .child("users/\(uid)/thoughts")
    return ref
  }()

  // Defines an encoder variable to encode JSON data.
  private let encoder = JSONEncoder()
  
  private let decoder = JSONDecoder()

  func listenForThoughts() {
    // Gets the database path that was previously defined.
    guard let databasePath = databasePath else {
      return
    }

    // Attaches a .childAdded observer to the database path.
    databasePath.observe(.childAdded) { [weak self] snapshot in

        // When a child node gets added to the database path, it returns a snapshot.
        guard
          let self = self,
          var json = snapshot.value as? [String: Any]
        else {
          return
        }

        // The id key of json stores the key variable of the snapshot.
        json["id"] = snapshot.key

        do {

          // The json Dictionary converts into a JSON Data object.
          let thoughtData = try JSONSerialization.data(withJSONObject: json)
          // The data decodes into a ThoughtModel object.
          let thought = try self.decoder.decode(ThoughtModel.self, from: thoughtData)
          // The new ThoughtModel object appends to the array of thoughts for display on screen.
          self.thoughts.append(thought)
        } catch {
          print("an error occurred", error)
        }
      }

  }

  func stopListening() {
    databasePath?.removeAllObservers()
  }

  func postThought() {
    // Gets the previously defined database path.
    guard let databasePath = databasePath else {
      return
    }

    // Returns immediately if there’s no text to post to the database.
    if newThoughtText.isEmpty {
      return
    }

    // Creates a ThoughtModel object from the text.
    let thought = ThoughtModel(text: newThoughtText)

    do {
      // Encodes the ThoughtModel into JSON data.
      let data = try encoder.encode(thought)

      // Converts the JSON data into a JSON Dictionary.
      let json = try JSONSerialization.jsonObject(with: data)

      // Writes the dictionary to the database path as a child node with an automatically generated ID.
      databasePath.childByAutoId()
        .setValue(json)
    } catch {
      print("an error occurred", error)
    }

  }
}
