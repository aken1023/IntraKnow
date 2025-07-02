#!/usr/bin/env node

// 修復前端依賴的腳本
const fs = require('fs');
const path = require('path');

console.log('🔧 檢查和修復前端依賴...');

// 檢查 package.json
if (!fs.existsSync('package.json')) {
    console.error('❌ package.json 不存在');
    process.exit(1);
}

const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));

// 檢查關鍵依賴
const requiredDeps = {
    'next': '^14.1.0',
    'react': '^18.2.0',
    'react-dom': '^18.2.0'
};

const requiredDevDeps = {
    'tailwindcss': '^3.4.1',
    'autoprefixer': '^10.4.17',
    'postcss': '^8.4.35',
    'typescript': '^5.3.3',
    '@types/node': '^20.11.17',
    '@types/react': '^18.2.55',
    '@types/react-dom': '^18.2.19'
};

let needsUpdate = false;

// 檢查並添加缺失的依賴
for (const [dep, version] of Object.entries(requiredDeps)) {
    if (!packageJson.dependencies || !packageJson.dependencies[dep]) {
        console.log(`⚠️ 缺少依賴: ${dep}`);
        if (!packageJson.dependencies) packageJson.dependencies = {};
        packageJson.dependencies[dep] = version;
        needsUpdate = true;
    }
}

for (const [dep, version] of Object.entries(requiredDevDeps)) {
    if (!packageJson.devDependencies || !packageJson.devDependencies[dep]) {
        console.log(`⚠️ 缺少開發依賴: ${dep}`);
        if (!packageJson.devDependencies) packageJson.devDependencies = {};
        packageJson.devDependencies[dep] = version;
        needsUpdate = true;
    }
}

if (needsUpdate) {
    fs.writeFileSync('package.json', JSON.stringify(packageJson, null, 2));
    console.log('✅ package.json 已更新');
}

// 檢查配置文件
const configFiles = [
    'tailwind.config.js',
    'tailwind.config.ts',
    'postcss.config.js',
    'postcss.config.mjs',
    'next.config.mjs',
    'next.config.js',
    'tsconfig.json'
];

console.log('📋 檢查配置文件:');
configFiles.forEach(file => {
    if (fs.existsSync(file)) {
        console.log(`✅ ${file} 存在`);
    } else {
        console.log(`⚠️ ${file} 不存在`);
    }
});

// 檢查關鍵目錄
const requiredDirs = ['app', 'components', 'public'];
console.log('📁 檢查目錄結構:');
requiredDirs.forEach(dir => {
    if (fs.existsSync(dir)) {
        console.log(`✅ ${dir}/ 目錄存在`);
    } else {
        console.log(`⚠️ ${dir}/ 目錄不存在`);
        fs.mkdirSync(dir, { recursive: true });
        console.log(`✅ 已創建 ${dir}/ 目錄`);
    }
});

console.log('🎉 依賴檢查完成！'); 