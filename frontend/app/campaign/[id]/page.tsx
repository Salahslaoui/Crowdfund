"use client"

import { Contract, formatEther, BrowserProvider, parseEther } from "ethers"
import { useEffect, useState } from "react"
import abi from "@/app/abi/Crowdfund.json"
import { Campaign } from "@/app/types"
import { useParams } from "next/navigation"
import { CONTRACT_ADDRESS } from "@/app/constants"

export default function CampaignPage() {
    const [error, setError] = useState<string | null>(null)
    const [campaign, setCampaign] = useState<Campaign | null>(null)
    const [action, setAction] = useState<string | null>(null)
    const [contribute, setContribute] = useState<number>(0)
    const { id } = useParams()

    async function LoadCampaign(id: string) {
        setError(null)
        try {
            const provider = new BrowserProvider(window.ethereum)
            const network = await provider.getNetwork()
            if (Number(network.chainId) != 31337) {
                setError("Wrong network switch to 31337")
                return
            }
            const contract = new Contract(CONTRACT_ADDRESS, abi.abi, provider)
            const camp: Campaign = await contract.getCampaign(id)
            setCampaign(camp)
        } catch(err) {
            setError("Load Campaign error: " + (err as Error).message)
        }
    }

    async function Contribute(id: string) {
        try {
            const provider = new BrowserProvider(window.ethereum)
            const network = await provider.getNetwork()
            if (Number(network.chainId) != 31337) {
                setError("Wrong network switch to 31337")
                return
            }
            await provider.send("eth_requestAccounts", [])
            const signer = await provider.getSigner()
            const contract = new Contract(CONTRACT_ADDRESS, abi.abi, signer)
            const tx = await contract.contribute(id, { value: parseEther(contribute.toString()) })
            await tx.wait()
            const camp = await contract.getCampaign(id)
            setCampaign(camp)
            setAction(null)
        } catch(err) {
            setError("Contribute Error: " + (err as Error).message)
        }
    }

    async function Refund(id: string) {
        try {
            const provider = new BrowserProvider(window.ethereum)
            const network = await provider.getNetwork()
            if (Number(network.chainId) != 31337) {
                setError("Wrong network switch to 31337")
                return
            }
            const signer = await provider.getSigner()
            const contract = new Contract(CONTRACT_ADDRESS, abi.abi, signer)
            const tx = await contract.refund(id)
            await tx.wait()
            const camp = await contract.getCampaign(id)
            setCampaign(camp)
        } catch(err) {
            setError("Refund Error: " + (err as Error).message)
        }
    }

    async function Withdraw(id: string) {
        try {
            const provider = new BrowserProvider(window.ethereum)
            const network = await provider.getNetwork()
            if (Number(network.chainId) != 31337) {
                setError("Wrong network switch to 31337")
                return
            }
            const signer = await provider.getSigner()
            const contract = new Contract(CONTRACT_ADDRESS, abi.abi, signer)
            const tx = await contract.withdraw(id)
            await tx.wait()
            const camp = await contract.getCampaign(id)
            setCampaign(camp)
        } catch(err) {
            setError("Withdraw Error: " + (err as Error).message)
        }
    }

    useEffect(() =>
        { 
            LoadCampaign(id as string)
        } 
        , [])
    return (
        <div style={{padding: "2rem"}}>
            <h2>Campaign Detail:</h2>
            {campaign &&
            <div>
                <p>Creator: {campaign.creator}</p>
                <p>Goal: {formatEther(campaign.goal)}ETH</p>
                <p>Deadline: {new Date(Number(campaign.deadline) * 1000).toLocaleString()}</p>
                <p>TotalFunded: {formatEther(campaign.totalFunded)}</p>
                <p>Claimed: {campaign.claimed ? "This Campaign is already claimed" : "This Campaign is not claimed yet"}</p>
            </div>}
            <form onSubmit={async (e) => {
                e.preventDefault()
                setError(null)
                if (!window.ethereum) {
                    setError("Please install Metamask!!")
                    return
                }
                if (action == "Contribute") {
                    await Contribute(id as string)
                }
                else if (action == "Refund") {
                    await Refund(id as string)
                }
                else if (action == "Withdraw") {
                    await Withdraw(id as string)
                }
                setContribute(0)
                
            }}>
                <input
                type="number"
                placeholder="Contribution"
                value={contribute}
                onChange={(e) => setContribute(Number(e.target.value))}
                ></input><br />
                <button type="submit" onClick={() => setAction("Contribute")}>Contribute</button><br />
                <button type="submit" onClick={() => setAction("Refund")}>Refund</button><br />
                <button type="submit" onClick={() => setAction("Withdraw")}>Withdraw</button><br />
            </form>
            {error && <p style={{color: "red"}}>{error}</p>}
        </div>
    )
}