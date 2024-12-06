#  SwiftUI-AssemblyAI Transcription Interface

 - Create new project
 - Upload audio file to firebase storage
 - Host python script on firebase functions with flask
 - Transcribe file and retrieve json response
 - Edit utterances and update in database
 - Create final document
 
 The following error can be thrown if the app's python environment is doesn't have AssemblyAI installed.
     ```
     line 1, in <module>
         import assemblyai as aai
     ModuleNotFoundError: No module named 'assemblyai'
     ```
 
 To fix, confirm that the version of Python being used by your Swift app is the one where you have installed assemblyai. If you're using Process in Swift, it's likely using the system-installed Python. You can find out which Python version your app is using by running the following code from within your Swift app:

    ```
     let process = Process()
     process.executableURL = URL(fileURLWithPath: "/usr/bin/python3") // or the path you're using
     process.arguments = ["-c", "import sys; print(sys.executable)"]

     let pipe = Pipe()
     process.standardOutput = pipe
     try process.run()
     process.waitUntilExit()

     let data = pipe.fileHandleForReading.readDataToEndOfFile()
     let output = String(data: data, encoding: .utf8)
     print(output ?? "Unknown Python version")
     ```
 
 This will output the path to the Python interpreter your Swift app is using. Once you know the Python interpreter, you can proceed to install the assemblyai module in the correct environment.
 
 To install the AssemblyAI package, install the AssemblyAI package in the python interpreter's environment


 Open a terminal and run the following. If it’s the system Python, you might need to use pip3:

     ``` /path/to/python3 -m pip install assemblyai ```

 If /usr/bin/python3 is being used, run:

     ``` /usr/bin/python3 -m pip install assemblyai ```
 
 
 If pip is not available, you might need to install it first:

     ```
     /path/to/python3 -m ensurepip --upgrade
     /path/to/python3 -m pip install --upgrade pip
     ```
