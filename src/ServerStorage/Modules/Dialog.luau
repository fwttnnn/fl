--!strict
local Dialog = {}

function Dialog.Show(label: TextLabel, text: string, delay: number)
    task.spawn(function()
        delay = delay or 0.07
        label.Text = ""

        for i = 1, #text do
            label.Text = string.sub(text, 1, i)
            task.wait(delay)
        end

        task.wait(4)
        label.Text = ""
    end)
end

return Dialog
