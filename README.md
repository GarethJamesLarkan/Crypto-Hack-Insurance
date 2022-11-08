# Crypto-Hack-Insurance

Crypto hack insurance is a web3 app which allows users to insure their crypto holdings incase of a hack! It works as follows:

  Users may create policies in which they insure their crypto! They will only be able to insure it if their funds are held in supported 
  exchanges (known as Holding Companies). Once a user has created a policy, they will be allocated a monthly installment which they need
  to pay regularly otherwise their polciy will close. This policy is worked out using a very simple algorithm which only incorporates the 
  level of trust in the holding company. Example: Some holding companies might have a safety rating of 10/100, therefore, if your money is
  held in said company, your premiums will be more than if the company had a safety rating of 90/100.
  
  The other actor in the system is the liquidity provider. This system allows the perfect oppurtunity to make your money work for you. If you
  opt in to becoming a liquidity provider, you will recieve a portion of all premiums being paid. Example: If the platform has $1m of liquidity
  and you have supplied $100 000! You will recieve 10% of all premiums being paid. This is a perfect oppurtunity to make your money work for you.
  
  Holding companies will need to be created, but can only be done by the owner of the contract! These will be the only companies users can hold 
  funds in to use this platform for insurance.
  
  FUTURE UPGRADES:
  
  1. Initial funding phase where users purchase CH Tokens and get rewarded with governance power.
  2. Stake the initial phase funds to make sure platform does not loose its liquidity.
  
Foundry setup:

  This app uses foundry, a brilliant environment which is quick and super useful. Follow this guide to set it up to run the contracts
  
  ### Install Foundry

  ```zsh
  curl -L https://foundry.paradigm.xyz | bash
  ```

  ### Update Foundry

  ```zsh
  foundryup
  ```

  ### Install Submodules

  ```zsh
  git submodule update --init --recursive
  ```
  
  ##Using Foundry
  
  To build the project, run:
  
  ```zsh
  forge b
  ```
  
  To run the tests for the project, run:
  
  ```zsh
  forge t
  ```
