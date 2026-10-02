"use client"

declare global {
    interface Window {
        ethereum?: any;
    }
}

import { useEffect, useState } from "react"
import { BrowserProvider, Contract, formatEther, parseEther } from "ethers"
import abi from "@/app/abi/Crowdfund.json"

const contract_address: string = "0x5FbDB2315678afecb367f032d93F642f64180aa3"

interface Campaign {
    creator: string,
    goal: bigint,
    deadline: bigint,
    totalFunded: bigint,
    claimed: boolean,
}

export default function Page() {
    const [error, setError] = useState<string | null>(null)
    const [account, setAccount] = useState<string | null>(null)
    const [loading, setLoading] = useState(false)
    const [form, setForm] = useState({ goal: 0, duration: 0 })
    const [success, setSuccess] = useState(false)
    const [campaigns, setCampaigns] = useState<Campaign[]>([])

    async function LoadCampaigns(): Promise<void> {
        setError(null)
        try {
            if (!window.ethereum) {
                setError("Metamask is not installed !!")
                return
            }
            const provider = new BrowserProvider(window.ethereum)
            const network = await provider.getNetwork()
            if (Number(network.chainId) != 31337) {
                setError("Wrong network change to 31337")
                return
            }
            const contract = new Contract(contract_address, abi.abi, provider)
            const camps: Campaign[] = await contract.getCampaigns()
            setCampaigns(camps)
        } catch(err) {
            setError("Load Error: " + (err as Error).message)
        }
    }

    useEffect(() => {
        LoadCampaigns()
    }, [])

    return (
        <div style={{padding: "2rem"}}>
            <ul>
                {campaigns.map((camp, ind) => 
                <li key={ind}>address: {camp.creator.slice(0, 5) + "..." + camp.creator.slice(-5)} must
                 achieve this goal: {formatEther(camp.goal)}ETH in {new Date(Number(camp.deadline) * 1000).toLocaleString()} actual funds: {formatEther(camp.totalFunded)}ETH</li>
                )}
            </ul>
            <form onSubmit={async (e) => {
                e.preventDefault()
                setError(null)
                try {
                    if (!window.ethereum) {
                        setError("Please install Metamask!!!")
                        return
                    }
                    const provider = new BrowserProvider(window.ethereum)
                    const network = await provider.getNetwork()
                    if (Number(network.chainId) != 31337) {
                        setError("Wrong network please change to 31337")
                        return
                    }
                    await provider.send("eth_requestAccounts", [])
                    const signer = await provider.getSigner()
                    const contract = new Contract(contract_address, abi.abi, signer)
                    const tx = await contract.createCampaign(parseEther(form.goal.toString()), form.duration * 24 * 60 * 60)
                    await tx.wait()
                    const Camps: Campaign[] = await contract.getCampaigns()
                    setCampaigns(Camps)
                    setForm({ goal: 0, duration: 0 })
                } catch(err) {
                    setError("Error in creating Campaign: " + (err as Error).message)
                }
            }}>
                <input 
                    placeholder="Goal"
                    value={form.goal}
                    onChange={(e) => setForm({...form, goal: Number(e.target.value)})}>
                </input><br />
                <input 
                    placeholder="Duration"
                    value={form.duration}
                    onChange={(e) => setForm({...form, duration: Number(e.target.value)})}>
                </input><br />
                <button type="submit">Submit</button>
            </form>
            {error && <p style={{color: "red"}}>{error}</p>}
        </div>
    )

}