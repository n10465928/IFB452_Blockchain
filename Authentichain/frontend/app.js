// frontend/app.js

let provider, signer;
let materialContract, mintContract, saleContract;

const materialAddress = '0xf8e81D47203A594245E36C48e151709F0C19fBe8';
const mintAddress = '0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47';
const saleAddress = '0x358AA13c52544ECCEF6B0ADD0f801012ADAD5eE3';

const loadABI = async (path) => (await (await fetch(path)).json()).abi;

window.onload = async () => {
  if (!window.ethereum) return alert("Please install MetaMask");

  provider = new ethers.providers.Web3Provider(window.ethereum);
  await provider.send("eth_requestAccounts", []);
  signer = provider.getSigner();

  const materialABI = await loadABI('./abi/MaterialTrackingContract.json');
  const mintABI = await loadABI('./abi/MintContract.json');
  const saleABI = await loadABI('./abi/OpenSale.json');

  materialContract = new ethers.Contract(materialAddress, materialABI, signer);
  mintContract = new ethers.Contract(mintAddress, mintABI, signer);
  saleContract = new ethers.Contract(saleAddress, saleABI, signer);
};

function setFeedback(id, message, success = true) {
  const el = document.getElementById(id);
  el.innerText = message;
  el.style.color = success ? 'green' : 'red';
}

// === Material Interaction ===
async function mintMaterial() {
  try {
    const origin = document.getElementById("origin").value;
    const supplier = document.getElementById("supplier").value;
    const weight = parseInt(document.getElementById("weight").value);
    const purity = document.getElementById("purity").value;
    const certHash = document.getElementById("certHash").value;

    const tx = await materialContract.mintMaterial(origin, supplier, weight, purity, certHash);
    await tx.wait();
    setFeedback('feedbackMaterial', 'Material successfully minted!');
  } catch (err) {
    setFeedback('feedbackMaterial', `Error: ${err.message}`, false);
  }
}

// === Mint Product Interaction ===
async function mintProduct() {
  try {
    const to = document.getElementById("to").value;
    const ids = document.getElementById("materialIds").value.split(",").map(id => parseInt(id.trim()));
    const uri = document.getElementById("metadataURI").value;

    const tx = await mintContract.mintProduct(to, ids, uri);
    await tx.wait();
    setFeedback('feedbackMint', 'Product NFT successfully minted!');
  } catch (err) {
    setFeedback('feedbackMint', `Error: ${err.message}`, false);
  }
}

// === Sale Interaction ===
async function purchaseProduct() {
  try {
    const tokenId = parseInt(document.getElementById("purchaseTokenId").value);
    const price = ethers.BigNumber.from(document.getElementById("priceWei").value);

    const tx = await saleContract.purchase(tokenId, { value: price });
    await tx.wait();
    setFeedback('feedbackPurchase', 'Purchase completed!');
  } catch (err) {
    setFeedback('feedbackPurchase', `Error: ${err.message}`, false);
  }
}