# Quex feed creation tool

## Description
Quex feed creation tool is made to make your start with Quex easier


## Setup

1. Initialize virtual environment
```bash
python -m venv venv
```
2. Activate virtual environment
```bash
source ./venv/bin/activate
```
3. Install requirements
```bash
pip install -r requirements.txt
```
4. Set up how the script will access the private key [here](create_feed.py#L62)
5. Configure your feed in `quex_feed.json`. Full set of options to describe your feed you can see in [IV1RequestRegistry models](../../interfaces/IV1RequestRegistry.sol)
6. Run script
```bash
python create_feed.py
```