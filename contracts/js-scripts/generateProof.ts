import { Noir } from "@noir-lang/noir_js";
import { ethers } from "ethers";
import { UltraHonkBackend } from "@aztec/bb.js";
import path from "path";
import { fileURLToPath } from "url";
import fs from "fs";

path.dirname(fileURLToPath(import.meta.url));
"../.../circuit/target/circuit.json";

//get the circuit file 
const circuitPath = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../circuit/target/circuit.json");
const circuit = JSON.parse(fs.readFileSync(circuitPath, 'utf8'));

export default async function generateProof() {
    try {
        const inputsArray = process.argv.slice(2);

        //initialize noir with the circuit
        const noir = new Noir(circuit);
        //initialize the backend using the circuit bytecode
        const bb = new UltraHonkBackend(circuit.bytecode, { threads: 1 });

        //create the inputs
        const inputs = {
            guess_hash: inputsArray[0],
            answer_hash: inputsArray[1],
            user: inputsArray[2]
        }
        const { witness } = await noir.execute(inputs);
        const originallog = console.log;
        //execute the circuit with the inputs to create the witness
        console.log = () => { }
        //generate the proof using backend with the witness
        const { proof } = await bb.generateProof(witness, { keccak: true });
        console.log = originallog;
        const encodedProof = ethers.AbiCoder.defaultAbiCoder().encode(
            ["bytes"],
            [proof]
        )

        //return the proof
        return encodedProof;
    }
    catch (error) {
        console.log(error);
        throw error;
    }
}

(async () => {
    generateProof()
        .then((proof) => {
            process.stdout.write(proof);
            process.exit(0);
        })
        .catch((error) => {
            console.log(error);
            process.exit(1);
        })
}
)();



