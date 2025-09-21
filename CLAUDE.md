
## Development Commands

Remember when creating/removing code files to add/remove them to the Xcode project.


```bash
scripts/build       # Build app
scripts/run         # Run the app
scripts/br          # Build and run the app
```

### iOS Simulator

If the SANDVAULT environment variable is defined then:
- ALWAYS use the MCP iOS Simulator tools (mcp__ios-simulator__*)
- NEVER use xcrun simctl or open -a Simulator commands directly
