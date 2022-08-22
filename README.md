# Metanoia

Metanoia is an ecosystem of products that aims to bring real world utility into the web3 space.



More information can be found in the following documents:

-  Whitepaper: https://docs.metanoia.country/

-  Public Discord group: https://discord.gg/pwUDCf6T

This code repository is actively developed on, and contains smart contracts and related files for Metanoia before they are deployed to the Polygon network.

THIS CODE IS NOT YET PRODUCTION READY, AND MAY HAVE SEVERE VULNERABILITIES OR ERRORS. IT HAS NOT YET BEEN AUDITED.

Installation instructions using node:
`yarn install`

Recommended to have the latest LTS Node version for compatibility with Hardhat (currently v16). 
Developed using Node.js version 16.15.0

Notes: most tests have a (boolean) marker `testEnabled` defined at the beginning of the file which enables/disables the test from running. This makes it feasible to run `npx hardhat test` to test only desired contracts, rather than all contracts which have tests.  
This is done to reduce the amount of wasted time on testing, since some files can take minutes to test individually.
