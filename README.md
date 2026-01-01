# PIPA Intelligence

A minimalist, cyberpunk-styled desktop AI chatbot built entirely in PowerShell using WPF. Powered by Google's Gemini 1.5 Flash model for fast, high-quality responses.

This is my first AI chatbot project — a standalone Windows app with a transparent, borderless window, subtle grid background, neon accents, and smooth chat experience.

## Features

- Clean, modern UI with dark theme and neon blue highlights
- Transparent, borderless, draggable window
- Animated "thinking" indicator with dots
- User messages right-aligned, AI responses left-aligned
- Send via button or Enter key
- Clear chat history
- Close button and full error handling for API issues

## Preview
<img width="1007" height="757" alt="image" src="https://github.com/user-attachments/assets/1b4741bb-1433-439d-acd2-d6971fe49cc8" />


## Requirements

- Windows 10/11
- PowerShell 5.1 or later (built-in on Windows)
- an AI API key (free tier available works aswell)

## Setup

1. Get a free Gemini API key (example of free AI API-limited):  
   https://ai.google.dev/ (create a project in Google AI Studio → Generate API key)

2. Download `PIPA Intelligence.ps1`

3. Edit the script:  
   Replace `"Your API KEY HERE"` with your actual key:
   ```powershell
   $apiKey = "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
