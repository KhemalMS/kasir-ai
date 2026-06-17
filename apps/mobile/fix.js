const fs = require('fs');
const path = require('path');

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(file => {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) {
            results = results.concat(walk(file));
        } else {
            if (file.endsWith('.dart')) results.push(file);
        }
    });
    return results;
}

const files = walk('lib');
files.forEach(file => {
    const content = fs.readFileSync(file, 'utf8');
    const newContent = content.replace(/ApiService\.(get|post|put|delete|getList)\('\/api\//g, "ApiService.$1('/");
    if (content !== newContent) {
        fs.writeFileSync(file, newContent, 'utf8');
        console.log(`Fixed ${file}`);
    }
});
