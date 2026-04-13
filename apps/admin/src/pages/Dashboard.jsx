import React from 'react';
import Header from '../components/Header';
import StatCards from '../components/StatCards';
import RevenueChart from '../components/RevenueChart';
import TopProducts from '../components/TopProducts';
import CriticalStock from '../components/CriticalStock';

export default function Dashboard() {
    return (
        <>
            <Header />
            <div className="z-10 flex-1 overflow-y-auto p-4 md:p-8 scroll-smooth">
                <div className="mx-auto max-w-7xl flex flex-col gap-6">
                    <StatCards />
                    <RevenueChart />
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 pb-6">
                        <TopProducts />
                        <CriticalStock />
                    </div>
                </div>
            </div>
        </>
    );
}
