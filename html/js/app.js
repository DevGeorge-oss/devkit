/* ── DevKit Debug — Frontend ─────────────────────────── */

const app         = document.getElementById('app')
const resourceList = document.getElementById('resource-list')
const resourceDetail = document.getElementById('resource-detail')
const logOutput   = document.getElementById('log-output')
const playerName  = document.getElementById('player-name')

let resources     = []
let selectedResource = null

/* ── NUI Message handler ─────────────────────────────── */
window.addEventListener('message', (e) => {
    const data = e.data
    switch (data.action) {
        case 'open':
            resources = data.resources || []
            if (data.player) playerName.textContent = data.player.name
            app.classList.remove('hidden')
            renderResourceList()
            addLog('Loaded ' + resources.length + ' resource(s) in ' + Config.ResourceFolder + '', 'info')
            break

        case 'close':
            app.classList.add('hidden')
            break

        case 'updateResources':
            resources = data.resources || []
            renderResourceList()
            // Re-select current resource if it's still in list
            if (selectedResource) {
                const updated = resources.find(r => r.name === selectedResource.name)
                if (updated) {
                    selectedResource = updated
                    renderResourceDetail(updated)
                }
            }
            break

        case 'log':
            addLog(data.message, data.level)
            break
    }
})

/* ── Resource list ───────────────────────────────────── */
function renderResourceList() {
    resourceList.innerHTML = ''
    if (resources.length === 0) {
        resourceList.innerHTML = '<div style="padding:12px;font-size:11px;color:var(--text-muted)">No resources found in ' + (Config.ResourceFolder || 'your resource folder') + '</div>'
        return
    }
    resources.forEach(r => {
        const item = document.createElement('div')
        item.className = 'resource-item' + (selectedResource?.name === r.name ? ' selected' : '')
        item.dataset.name = r.name
        item.innerHTML = `
            <span class="resource-dot dot-${r.state}"></span>
            <span class="resource-name">${r.name}</span>
        `
        item.addEventListener('click', () => selectResource(r))
        resourceList.appendChild(item)
    })
}

function selectResource(r) {
    selectedResource = r
    // Update sidebar selection
    document.querySelectorAll('.resource-item').forEach(el => {
        el.classList.toggle('selected', el.dataset.name === r.name)
    })
    // Switch to resources tab
    switchTab('resources')
    renderResourceDetail(r)
}

function renderResourceDetail(r) {
    const stateLabel = { running: 'Running', stopped: 'Stopped', starting: 'Starting', missing: 'Missing' }
    const badgeClass = 'badge-' + r.state

    let itemsHTML = ''
    if (r.items && r.items.length > 0) {
        itemsHTML = `
            <div class="detail-section">
                <h4>Quick Give Items</h4>
                <div class="items-list">
                    ${r.items.map(item => `
                        <div class="item-chip" data-item="${item}" title="Give 1x ${item}">
                            ${item}
                            <span class="item-chip-amount">x1</span>
                        </div>
                    `).join('')}
                    ${r.items.length > 1 ? `
                        <div class="item-chip give-all-chip" title="Give all items">
                            Give All
                            <span class="item-chip-amount">x5</span>
                        </div>
                    ` : ''}
                </div>
            </div>
        `
    }

    let commandsHTML = ''
    if (r.commands && r.commands.length > 0) {
        commandsHTML = `
            <div class="detail-section">
                <h4>Debug Commands</h4>
                <div class="btn-row">
                    ${r.commands.map(cmd => `
                        <button class="action-btn" data-cmd="${cmd}">/${cmd}</button>
                    `).join('')}
                </div>
            </div>
        `
    }

    resourceDetail.innerHTML = `
        <div class="detail-header">
            <div style="display:flex;align-items:center;gap:10px;margin-bottom:6px;">
                <span class="detail-name">${r.name}</span>
                <span class="status-badge ${badgeClass}">${stateLabel[r.state] || r.state}</span>
            </div>
            <div class="detail-meta">
                <span>${r.description || 'No description'}</span>
                <span>v${r.version}</span>
            </div>
        </div>

        <div class="detail-section">
            <h4>Resource Controls</h4>
            <div class="btn-row">
                <button class="action-btn green" id="btn-restart">↺ Restart</button>
                <button class="action-btn green" id="btn-start">▶ Start</button>
                <button class="action-btn red"   id="btn-stop">■ Stop</button>
            </div>
        </div>

        ${itemsHTML}
        ${commandsHTML}

        <div class="detail-section">
            <h4>Resource Path</h4>
            <div class="coords-box" style="font-size:10px;color:var(--text-muted)">${r.path}</div>
        </div>
    `

    // Resource control buttons
    document.getElementById('btn-restart').addEventListener('click', () => {
        addLog('Restarting ' + r.name + '...', 'warn')
        fetch(`https://devkit/restartResource`, {
            method: 'POST',
            body: JSON.stringify({ resource: r.name })
        })
    })

    document.getElementById('btn-start').addEventListener('click', () => {
        addLog('Starting ' + r.name + '...', 'info')
        fetch(`https://devkit/startResource`, {
            method: 'POST',
            body: JSON.stringify({ resource: r.name })
        })
    })

    document.getElementById('btn-stop').addEventListener('click', () => {
        addLog('Stopping ' + r.name + '...', 'warn')
        fetch(`https://devkit/stopResource`, {
            method: 'POST',
            body: JSON.stringify({ resource: r.name })
        })
    })

    // Item chips
    document.querySelectorAll('.item-chip[data-item]').forEach(chip => {
        chip.addEventListener('click', () => {
            const item = chip.dataset.item
            fetch(`https://devkit/giveItems`, {
                method: 'POST',
                body: JSON.stringify({ items: [{ name: item, amount: 1 }] })
            })
            addLog('Gave 1x ' + item, 'success')
        })
    })

    const giveAllChip = document.querySelector('.give-all-chip')
    if (giveAllChip) {
        giveAllChip.addEventListener('click', () => {
            const items = r.items.map(name => ({ name, amount: 5 }))
            fetch(`https://devkit/giveItems`, {
                method: 'POST',
                body: JSON.stringify({ items })
            })
            addLog('Gave all items for ' + r.name, 'success')
        })
    }

    // Debug command buttons
    document.querySelectorAll('[data-cmd]').forEach(btn => {
        btn.addEventListener('click', () => {
            const cmd = btn.dataset.cmd
            fetch(`https://devkit/runCommand`, {
                method: 'POST',
                body: JSON.stringify({ command: cmd })
            })
            addLog('Running /' + cmd, 'info')
        })
    })
}

/* ── Tab switching ───────────────────────────────────── */
function switchTab(name) {
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.tab === name)
    })
    document.querySelectorAll('.tab-content').forEach(panel => {
        panel.classList.toggle('active', panel.id === 'tab-' + name)
    })
}

document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => switchTab(btn.dataset.tab))
})

/* ── Sidebar buttons ─────────────────────────────────── */
document.getElementById('btn-close').addEventListener('click', () => {
    fetch(`https://devkit/close`, { method: 'POST', body: JSON.stringify({}) })
})

document.getElementById('btn-refresh').addEventListener('click', () => {
    addLog('Refreshing resource list...', 'info')
    fetch(`https://devkit/refreshResources`, { method: 'POST', body: JSON.stringify({}) })
})

/* ── Tools tab ───────────────────────────────────────── */
document.getElementById('btn-fix-skin').addEventListener('click', () => {
    fetch(`https://devkit/fixSkin`, { method: 'POST', body: JSON.stringify({}) })
    addLog('Resetting skin...', 'info')
})

document.getElementById('btn-get-coords').addEventListener('click', () => {
    fetch(`https://devkit/getCoords`, { method: 'POST', body: JSON.stringify({}) })
        .then(r => r.json())
        .then(coords => {
            const box = document.getElementById('coords-display')
            const str = `vec4(${coords.x}, ${coords.y}, ${coords.z}, ${coords.h})`
            box.textContent = str
            box.classList.remove('hidden')
            // Copy to clipboard attempt
            try { navigator.clipboard.writeText(str) } catch(e) {}
            addLog('Coords: ' + str, 'success')
        })
})

document.getElementById('btn-tp').addEventListener('click', () => {
    const x = document.getElementById('tp-x').value
    const y = document.getElementById('tp-y').value
    const z = document.getElementById('tp-z').value
    if (!x || !y || !z) return
    fetch(`https://devkit/teleport`, {
        method: 'POST',
        body: JSON.stringify({ x, y, z })
    })
})

document.querySelectorAll('.quick-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        fetch(`https://devkit/teleport`, {
            method: 'POST',
            body: JSON.stringify({ x: btn.dataset.x, y: btn.dataset.y, z: btn.dataset.z })
        })
        addLog('Teleporting to ' + btn.textContent.trim(), 'info')
    })
})

document.getElementById('btn-give').addEventListener('click', () => {
    const item   = document.getElementById('give-item').value.trim()
    const amount = parseInt(document.getElementById('give-amount').value) || 1
    if (!item) return
    fetch(`https://devkit/giveItems`, {
        method: 'POST',
        body: JSON.stringify({ items: [{ name: item, amount }] })
    })
    addLog('Gave ' + amount + 'x ' + item, 'success')
})

document.querySelectorAll('.quick-give').forEach(btn => {
    btn.addEventListener('click', () => {
        fetch(`https://devkit/giveItems`, {
            method: 'POST',
            body: JSON.stringify({ items: [{ name: btn.dataset.item, amount: parseInt(btn.dataset.amount) }] })
        })
        addLog('Gave ' + btn.dataset.amount + 'x ' + btn.dataset.item, 'success')
    })
})

document.getElementById('btn-run-cmd').addEventListener('click', () => {
    const cmd = document.getElementById('cmd-input').value.trim()
    if (!cmd) return
    fetch(`https://devkit/runCommand`, {
        method: 'POST',
        body: JSON.stringify({ command: cmd })
    })
    addLog('Running /' + cmd, 'info')
    document.getElementById('cmd-input').value = ''
})

document.getElementById('cmd-input').addEventListener('keydown', e => {
    if (e.key === 'Enter') document.getElementById('btn-run-cmd').click()
})

/* ── Console / Log ───────────────────────────────────── */
function addLog(msg, level = 'info') {
    const now  = new Date()
    const time = now.toTimeString().slice(0, 8)
    const line = document.createElement('div')
    line.className = 'log-line ' + level
    line.innerHTML = `<span class="log-time">${time}</span><span class="log-msg">${msg}</span>`
    logOutput.appendChild(line)

    const autoScroll = document.getElementById('log-autoscroll').checked
    if (autoScroll) logOutput.scrollTop = logOutput.scrollHeight

    // Keep log to last 200 entries
    while (logOutput.children.length > 200) logOutput.removeChild(logOutput.firstChild)
}

document.getElementById('btn-clear-log').addEventListener('click', () => {
    logOutput.innerHTML = ''
})

/* ── Enter key on give input ─────────────────────────── */
document.getElementById('give-item').addEventListener('keydown', e => {
    if (e.key === 'Enter') document.getElementById('btn-give').click()
})
