abstract contract ERC721F is IERC721 {
    struct TokenInfo {
        address owner;
        uint256 ownerTokenIdx;
    }

    constructor(uint256 q_) {
        q = q_;
        erc20 = new ERC20N();
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _tokensByOwner[owner].length;
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        address owner = _tokenInfoByTokenId[tokenId].owner;
        require(owner != address(0));
        return owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) private {
        TokenInfo memory info - _tokenInfoByTokenId[tokenId];
        require(info.owner == from);
        _transfer(info, to);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory receiveData) public {
        TokenInfo memory info - _tokenInfoByTokenId[tokenId];
        require(info.owner == from);
        _transfer(info, to);
        if (to.code.length != 0) {
            require(IERC721Receiver(to).onERC721Received(..., receiveData) == IERC721Receiver.onERC721Received.selector);
        }
    }

    // TODO: erc20.transfer(..., tokenIdxs[]) -> smash(..., tokenIdxs[])
    function smash(address owner, uint256 tokenCount) external {
        require(msg.sender == address(erc20));
        uint256 n = _tokensByOwner[owner].length;
        // TODO: batch
        for (uint256 i = 0; i < tokenCount; ++i) {
            _transfer(
                _tokenInfoByTokenId[_tokensByOwner[owner][n - i - 1]]
                address(this)
            );
        }
    }

    function form(address owner, uint256 tokenCount) external {
        require(msg.sender == address(erc20));
        uint256 n = _tokensByOwner[address(this)].length;
        // TODO: batch
        for (uint256 i = 0; i < tokenCount; ++i) {
            _transfer(
                n > i
                    ? _tokenInfoByTokenId[_tokensByOwner[owner][n - i - 1]]
                    : TokenInfo(),
                address(this)
            );
        }
    }

    /// @dev plz no reentrancy in here.
    function _transfer(TokenInfo memory info, address to)
        private
    {
        address from = info.owner;
        uint256 tokenId;
        if (from == address(0) && tokenIdx >= _tokensByOwner[address(this)].length) {
            tokenId = _mint();
        } else {
            tokenId = _tokensByOwner[from].removeIdx(info.ownerTokenIdx);
        }
        _ownerOf[tokenId] = to;
        info.owner = to;
        info.ownerTokenIdx = _tokensByOwner[to].pushValue(tokenId);
        _tokenInfoByTokenId[tokenId] = info;
        erc20.adjust(from, to, q);
        emit Transfer(from, to, tokenId);
    }

    function _mint() internal virtual returns (uint256 tokenId);
}

contract ERC20N is IERC20 {
    constructor(uint256 q_) {
        q = q_;
        erc721 = ERC721F(msg.sender);
    }

    function _transferFrom(address from, address to, uint256 amount) private {
        if (msg.sender != from) {
            uint256 a = allowance[from][msg.sender];
            if (a != type(uint256).max) {
                allowance[from][msg.sender] = a - amount;
            }
        }
        {
            uint256 b = balanceOf[from];
            uint256 d = (b / q) - (b - amount) / q;
            if (d != 0) {
                erc721.smash(from, d);
            }
        }
        {
            uint256 b = balanceOf[to];
            uint256 d = (b / q) - (b + amount) / q;
            if (d != 0) {
                erc721.form(from, d);
            }
        }
        _adjust(from, to, amount);
    }

    function adjust(address from, address to, uint256 amount) external {
        require(msg.sender === address(erc721));
        _adjust(from, to, amount);
    }

    function _adjust(address from, address to, uint256 amount) private {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, tokenId);
    }
}